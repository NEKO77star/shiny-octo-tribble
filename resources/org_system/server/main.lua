--[[
    Resource: org_system
    File: server/main.lua
    Purpose: Server-side logic for Organization & Territory System
    
    Responsibilities:
    - Organization CRUD operations (create, read, update, delete)
    - Member management (invite, kick, promote, demote)
    - Asset management (add, remove, transfer)
    - Hidden account operations
    - Territory control and conflict management
    
    Database tables used:
    - organizations
    - organization_members
    - org_assets
    - hidden_accounts
    - territories
    - territory_conflicts
    - org_logs
    
    Events:
    - server:org:createOrganization
    - server:org:disbandOrganization
    - server:org:inviteMember
    - server:org:kickMember
    - server:org:promoteMember
    - server:org:demoteMember
    - server:org:updateSettings
    - server:org:startConflict
    - server:org:resolveConflict
    
    Callbacks:
    - qb_org:server:getOrganization
    - qb_org:server:getMembers
    - qb_org:server:getAssets
    - qb_org:server:getTerritories
    - qb_org:server:getLogs
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- Cache for organizations to reduce DB queries
local OrganizationCache = {}
local MemberCache = {}

-- =====================================
-- HELPER FUNCTIONS
-- =====================================

local function GetPlayerCitizenId(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.citizenid
    end
    return nil
end

local function GetPlayerOrganization(citizenid)
    local result = MySQL.query.await('SELECT org_id, role FROM organization_members WHERE citizenid = ?', {citizenid})
    if result and result[1] then
        return result[1].org_id, result[1].role
    end
    return nil, nil
end

local function HasPermission(role, permission)
    if Config.Roles[role] and Config.Roles[role].permissions then
        return Config.Roles[role].permissions[permission] == true
    end
    return false
end

local function LogAction(orgId, actorCid, actionType, targetCid, details)
    MySQL.insert('INSERT INTO org_logs (org_id, action_type, actor_cid, target_cid, details) VALUES (?, ?, ?, ?, ?)', 
        {orgId, actionType, actorCid, targetCid, details})
end

local function RefreshOrganizationCache(orgId)
    local result = MySQL.query.await('SELECT * FROM organizations WHERE id = ?', {orgId})
    if result and result[1] then
        OrganizationCache[orgId] = result[1]
    end
end

local function RefreshMemberCache(orgId)
    local result = MySQL.query.await('SELECT * FROM organization_members WHERE org_id = ?', {orgId})
    if result then
        MemberCache[orgId] = result
    end
end

-- =====================================
-- ORGANIZATION CRUD OPERATIONS
-- =====================================

-- Create a new organization
RegisterNetEvent('server:org:createOrganization', function(name, orgType)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Error: Could not verify player identity', 'error')
        return
    end
    
    -- Check if player is already in an organization
    local existingOrgId, _ = GetPlayerOrganization(citizenid)
    if existingOrgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are already a member of an organization', 'error')
        return
    end
    
    -- Validate organization type
    if not Config.OrgTypes[orgType] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid organization type', 'error')
        return
    end
    
    -- Check if organization name already exists
    local nameCheck = MySQL.query.await('SELECT id FROM organizations WHERE name = ?', {name})
    if nameCheck and nameCheck[1] then
        TriggerClientEvent('QBCore:Notify', src, 'An organization with this name already exists', 'error')
        return
    end
    
    -- Create organization
    local orgId = MySQL.insert.await('INSERT INTO organizations (name, type, leader_cid) VALUES (?, ?, ?)', 
        {name, orgType, citizenid})
    
    if orgId then
        -- Add creator as boss
        local roleConfig = Config.Roles['boss']
        MySQL.insert('INSERT INTO organization_members (org_id, citizenid, role, salary, share_percent) VALUES (?, ?, ?, ?, ?)',
            {orgId, citizenid, 'boss', roleConfig.defaultSalary, roleConfig.defaultShare})
        
        -- Create default cash asset
        MySQL.insert('INSERT INTO org_assets (org_id, asset_type, identifier, amount, hidden) VALUES (?, ?, ?, ?, ?)',
            {orgId, 'cash', 'main_treasury', 0, false})
        
        -- Log the creation
        LogAction(orgId, citizenid, 'create_organization', nil, json.encode({name = name, type = orgType}))
        
        RefreshOrganizationCache(orgId)
        RefreshMemberCache(orgId)
        
        TriggerClientEvent('QBCore:Notify', src, 'Organization "' .. name .. '" created successfully', 'success')
        TriggerClientEvent('client:org:updateOrgUI', src)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to create organization', 'error')
    end
end)

-- Disband an organization
RegisterNetEvent('server:org:disbandOrganization', function(orgId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local playerOrgId, role = GetPlayerOrganization(citizenid)
    
    if not playerOrgId or playerOrgId ~= orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not a member of this organization', 'error')
        return
    end
    
    if role ~= 'boss' then
        TriggerClientEvent('QBCore:Notify', src, 'Only the boss can disband the organization', 'error')
        return
    end
    
    -- Get organization info before deletion
    local org = MySQL.query.await('SELECT name FROM organizations WHERE id = ?', {orgId})
    local orgName = org and org[1] and org[1].name or 'Unknown'
    
    -- Delete organization (cascades to members, assets, logs)
    MySQL.query.await('DELETE FROM organizations WHERE id = ?', {orgId})
    
    -- Clear cache
    OrganizationCache[orgId] = nil
    MemberCache[orgId] = nil
    
    -- Notify all online members
    local Players = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(Players) do
        TriggerClientEvent('client:org:organizationDisbanded', playerId, orgId)
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Organization "' .. orgName .. '" has been disbanded', 'success')
end)

-- =====================================
-- MEMBER MANAGEMENT
-- =====================================

-- Invite a player to the organization
RegisterNetEvent('server:org:inviteMember', function(targetCitizenId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'invite') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to invite members', 'error')
        return
    end
    
    -- Check if target is already in an organization
    local targetOrgId, _ = GetPlayerOrganization(targetCitizenId)
    if targetOrgId then
        TriggerClientEvent('QBCore:Notify', src, 'This player is already in an organization', 'error')
        return
    end
    
    -- Check member limit
    local org = MySQL.query.await('SELECT type FROM organizations WHERE id = ?', {orgId})
    if org and org[1] then
        local maxMembers = Config.OrgTypes[org[1].type].maxMembers
        local currentMembers = MySQL.query.await('SELECT COUNT(*) as count FROM organization_members WHERE org_id = ?', {orgId})
        if currentMembers and currentMembers[1] and currentMembers[1].count >= maxMembers then
            TriggerClientEvent('QBCore:Notify', src, 'Organization has reached maximum member limit', 'error')
            return
        end
    end
    
    -- Add as associate
    local roleConfig = Config.Roles['associate']
    MySQL.insert('INSERT INTO organization_members (org_id, citizenid, role, salary, share_percent) VALUES (?, ?, ?, ?, ?)',
        {orgId, targetCitizenId, 'associate', roleConfig.defaultSalary, roleConfig.defaultShare})
    
    LogAction(orgId, citizenid, 'invite_member', targetCitizenId, nil)
    RefreshMemberCache(orgId)
    
    -- Notify the inviter
    TriggerClientEvent('QBCore:Notify', src, 'Player invited successfully', 'success')
    
    -- Notify the invited player if online
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    if targetPlayer then
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been invited to an organization', 'success')
        TriggerClientEvent('client:org:updateOrgUI', targetPlayer.PlayerData.source)
    end
end)

-- Kick a member from the organization
RegisterNetEvent('server:org:kickMember', function(targetCitizenId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'kick') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to kick members', 'error')
        return
    end
    
    -- Cannot kick yourself
    if targetCitizenId == citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You cannot kick yourself', 'error')
        return
    end
    
    -- Get target's role
    local targetResult = MySQL.query.await('SELECT role FROM organization_members WHERE org_id = ? AND citizenid = ?', {orgId, targetCitizenId})
    if not targetResult or not targetResult[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Player is not in your organization', 'error')
        return
    end
    
    local targetRole = targetResult[1].role
    
    -- Cannot kick someone of equal or higher rank
    if Config.Roles[targetRole].level >= Config.Roles[role].level then
        TriggerClientEvent('QBCore:Notify', src, 'You cannot kick someone of equal or higher rank', 'error')
        return
    end
    
    MySQL.query.await('DELETE FROM organization_members WHERE org_id = ? AND citizenid = ?', {orgId, targetCitizenId})
    
    LogAction(orgId, citizenid, 'kick_member', targetCitizenId, nil)
    RefreshMemberCache(orgId)
    
    TriggerClientEvent('QBCore:Notify', src, 'Member kicked successfully', 'success')
    
    -- Notify the kicked player if online
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    if targetPlayer then
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been kicked from the organization', 'error')
        TriggerClientEvent('client:org:updateOrgUI', targetPlayer.PlayerData.source)
    end
end)

-- Promote a member
RegisterNetEvent('server:org:promoteMember', function(targetCitizenId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'promote') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to promote members', 'error')
        return
    end
    
    -- Get target's current role
    local targetResult = MySQL.query.await('SELECT role FROM organization_members WHERE org_id = ? AND citizenid = ?', {orgId, targetCitizenId})
    if not targetResult or not targetResult[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Player is not in your organization', 'error')
        return
    end
    
    local targetRole = targetResult[1].role
    local roleOrder = {'associate', 'member', 'executive', 'boss'}
    local currentIndex = 0
    
    for i, r in ipairs(roleOrder) do
        if r == targetRole then
            currentIndex = i
            break
        end
    end
    
    if currentIndex >= #roleOrder then
        TriggerClientEvent('QBCore:Notify', src, 'Member is already at the highest rank', 'error')
        return
    end
    
    local newRole = roleOrder[currentIndex + 1]
    
    -- Cannot promote to equal or higher than your own rank (except boss can promote to executive)
    if Config.Roles[newRole].level >= Config.Roles[role].level and role ~= 'boss' then
        TriggerClientEvent('QBCore:Notify', src, 'You cannot promote someone to your rank or higher', 'error')
        return
    end
    
    local newRoleConfig = Config.Roles[newRole]
    MySQL.query.await('UPDATE organization_members SET role = ?, salary = ?, share_percent = ? WHERE org_id = ? AND citizenid = ?',
        {newRole, newRoleConfig.defaultSalary, newRoleConfig.defaultShare, orgId, targetCitizenId})
    
    LogAction(orgId, citizenid, 'promote_member', targetCitizenId, json.encode({from = targetRole, to = newRole}))
    RefreshMemberCache(orgId)
    
    TriggerClientEvent('QBCore:Notify', src, 'Member promoted to ' .. newRoleConfig.label, 'success')
    
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    if targetPlayer then
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been promoted to ' .. newRoleConfig.label, 'success')
        TriggerClientEvent('client:org:updateOrgUI', targetPlayer.PlayerData.source)
    end
end)

-- Demote a member
RegisterNetEvent('server:org:demoteMember', function(targetCitizenId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'demote') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to demote members', 'error')
        return
    end
    
    -- Get target's current role
    local targetResult = MySQL.query.await('SELECT role FROM organization_members WHERE org_id = ? AND citizenid = ?', {orgId, targetCitizenId})
    if not targetResult or not targetResult[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Player is not in your organization', 'error')
        return
    end
    
    local targetRole = targetResult[1].role
    
    -- Cannot demote someone of equal or higher rank
    if Config.Roles[targetRole].level >= Config.Roles[role].level then
        TriggerClientEvent('QBCore:Notify', src, 'You cannot demote someone of equal or higher rank', 'error')
        return
    end
    
    local roleOrder = {'associate', 'member', 'executive', 'boss'}
    local currentIndex = 0
    
    for i, r in ipairs(roleOrder) do
        if r == targetRole then
            currentIndex = i
            break
        end
    end
    
    if currentIndex <= 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Member is already at the lowest rank', 'error')
        return
    end
    
    local newRole = roleOrder[currentIndex - 1]
    local newRoleConfig = Config.Roles[newRole]
    
    MySQL.query.await('UPDATE organization_members SET role = ?, salary = ?, share_percent = ? WHERE org_id = ? AND citizenid = ?',
        {newRole, newRoleConfig.defaultSalary, newRoleConfig.defaultShare, orgId, targetCitizenId})
    
    LogAction(orgId, citizenid, 'demote_member', targetCitizenId, json.encode({from = targetRole, to = newRole}))
    RefreshMemberCache(orgId)
    
    TriggerClientEvent('QBCore:Notify', src, 'Member demoted to ' .. newRoleConfig.label, 'success')
    
    local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetCitizenId)
    if targetPlayer then
        TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 'You have been demoted to ' .. newRoleConfig.label, 'error')
        TriggerClientEvent('client:org:updateOrgUI', targetPlayer.PlayerData.source)
    end
end)

-- Update member salary and share
RegisterNetEvent('server:org:updateMemberCompensation', function(targetCitizenId, salary, sharePercent)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'editSettings') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to edit settings', 'error')
        return
    end
    
    salary = math.max(0, tonumber(salary) or 0)
    sharePercent = math.max(0, math.min(100, tonumber(sharePercent) or 0))
    
    MySQL.query.await('UPDATE organization_members SET salary = ?, share_percent = ? WHERE org_id = ? AND citizenid = ?',
        {salary, sharePercent, orgId, targetCitizenId})
    
    LogAction(orgId, citizenid, 'update_compensation', targetCitizenId, json.encode({salary = salary, share = sharePercent}))
    RefreshMemberCache(orgId)
    
    TriggerClientEvent('QBCore:Notify', src, 'Compensation updated', 'success')
end)

-- =====================================
-- ASSET MANAGEMENT
-- =====================================

-- Add or update an asset
RegisterNetEvent('server:org:addAsset', function(assetType, identifier, amount, hidden)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'manageAssets') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to manage assets', 'error')
        return
    end
    
    hidden = hidden or false
    amount = math.max(0, tonumber(amount) or 0)
    
    -- Check if asset already exists
    local existing = MySQL.query.await('SELECT id, amount FROM org_assets WHERE org_id = ? AND asset_type = ? AND identifier = ?',
        {orgId, assetType, identifier})
    
    if existing and existing[1] then
        -- Update existing asset
        MySQL.query.await('UPDATE org_assets SET amount = amount + ?, hidden = ? WHERE id = ?',
            {amount, hidden, existing[1].id})
    else
        -- Create new asset
        MySQL.insert('INSERT INTO org_assets (org_id, asset_type, identifier, amount, hidden) VALUES (?, ?, ?, ?, ?)',
            {orgId, assetType, identifier, amount, hidden})
    end
    
    LogAction(orgId, citizenid, 'add_asset', nil, json.encode({type = assetType, identifier = identifier, amount = amount}))
    
    TriggerClientEvent('QBCore:Notify', src, 'Asset added/updated', 'success')
    TriggerClientEvent('client:org:updateOrgUI', src)
end)

-- Remove or reduce an asset
RegisterNetEvent('server:org:removeAsset', function(assetId, amount)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'manageAssets') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to manage assets', 'error')
        return
    end
    
    local asset = MySQL.query.await('SELECT * FROM org_assets WHERE id = ? AND org_id = ?', {assetId, orgId})
    if not asset or not asset[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Asset not found', 'error')
        return
    end
    
    amount = math.max(0, tonumber(amount) or 0)
    
    if amount >= asset[1].amount then
        MySQL.query.await('DELETE FROM org_assets WHERE id = ?', {assetId})
    else
        MySQL.query.await('UPDATE org_assets SET amount = amount - ? WHERE id = ?', {amount, assetId})
    end
    
    LogAction(orgId, citizenid, 'remove_asset', nil, json.encode({assetId = assetId, amount = amount}))
    
    TriggerClientEvent('QBCore:Notify', src, 'Asset updated', 'success')
    TriggerClientEvent('client:org:updateOrgUI', src)
end)

-- =====================================
-- HIDDEN ACCOUNTS
-- =====================================

-- Create a hidden account
RegisterNetEvent('server:org:createHiddenAccount', function(ownerType, ownerId, currency)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    -- Verify ownership
    if ownerType == 'player' and ownerId ~= citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid account ownership', 'error')
        return
    end
    
    if ownerType == 'organization' then
        local orgId, role = GetPlayerOrganization(citizenid)
        if not orgId or tostring(orgId) ~= tostring(ownerId) then
            TriggerClientEvent('QBCore:Notify', src, 'You are not in this organization', 'error')
            return
        end
        if not HasPermission(role, 'manageAssets') then
            TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to create hidden accounts', 'error')
            return
        end
    end
    
    currency = currency or 'yen'
    
    -- Check if account already exists
    local existing = MySQL.query.await('SELECT id FROM hidden_accounts WHERE owner_type = ? AND owner_id = ? AND currency = ?',
        {ownerType, ownerId, currency})
    
    if existing and existing[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Hidden account already exists', 'error')
        return
    end
    
    MySQL.insert('INSERT INTO hidden_accounts (owner_type, owner_id, balance, currency, risk_level) VALUES (?, ?, ?, ?, ?)',
        {ownerType, ownerId, 0, currency, 0})
    
    TriggerClientEvent('QBCore:Notify', src, 'Hidden account created', 'success')
end)

-- Deposit to hidden account
RegisterNetEvent('server:org:depositHiddenAccount', function(accountId, amount)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid amount', 'error')
        return
    end
    
    -- Get account and verify ownership
    local account = MySQL.query.await('SELECT * FROM hidden_accounts WHERE id = ?', {accountId})
    if not account or not account[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Account not found', 'error')
        return
    end
    
    local hasAccess = false
    if account[1].owner_type == 'player' and account[1].owner_id == citizenid then
        hasAccess = true
    elseif account[1].owner_type == 'organization' then
        local orgId, role = GetPlayerOrganization(citizenid)
        if orgId and tostring(orgId) == tostring(account[1].owner_id) and HasPermission(role, 'manageAssets') then
            hasAccess = true
        end
    end
    
    if not hasAccess then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have access to this account', 'error')
        return
    end
    
    -- Check if player has enough cash
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.money.cash < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough cash', 'error')
        return
    end
    
    -- Remove cash and add to hidden account
    Player.Functions.RemoveMoney('cash', amount, 'hidden_account_deposit')
    
    -- Increase risk level slightly with each deposit
    local newRisk = math.min(100, account[1].risk_level + 1)
    MySQL.query.await('UPDATE hidden_accounts SET balance = balance + ?, risk_level = ? WHERE id = ?',
        {amount, newRisk, accountId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Deposited ¥' .. amount .. ' to hidden account', 'success')
    TriggerClientEvent('client:org:updateOrgUI', src)
end)

-- Withdraw from hidden account
RegisterNetEvent('server:org:withdrawHiddenAccount', function(accountId, amount)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid amount', 'error')
        return
    end
    
    local account = MySQL.query.await('SELECT * FROM hidden_accounts WHERE id = ?', {accountId})
    if not account or not account[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Account not found', 'error')
        return
    end
    
    local hasAccess = false
    if account[1].owner_type == 'player' and account[1].owner_id == citizenid then
        hasAccess = true
    elseif account[1].owner_type == 'organization' then
        local orgId, role = GetPlayerOrganization(citizenid)
        if orgId and tostring(orgId) == tostring(account[1].owner_id) and HasPermission(role, 'manageAssets') then
            hasAccess = true
        end
    end
    
    if not hasAccess then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have access to this account', 'error')
        return
    end
    
    if account[1].balance < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Insufficient balance', 'error')
        return
    end
    
    MySQL.query.await('UPDATE hidden_accounts SET balance = balance - ? WHERE id = ?', {amount, accountId})
    
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney('cash', amount, 'hidden_account_withdrawal')
    
    TriggerClientEvent('QBCore:Notify', src, 'Withdrew ¥' .. amount .. ' from hidden account', 'success')
    TriggerClientEvent('client:org:updateOrgUI', src)
end)

-- =====================================
-- TERRITORY MANAGEMENT
-- =====================================

-- Start a territory conflict
RegisterNetEvent('server:org:startConflict', function(territoryId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    if not HasPermission(role, 'manageTerritories') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to manage territories', 'error')
        return
    end
    
    -- Check org type can own territory
    local org = MySQL.query.await('SELECT type FROM organizations WHERE id = ?', {orgId})
    if not org or not org[1] or not Config.OrgTypes[org[1].type].canOwnTerritory then
        TriggerClientEvent('QBCore:Notify', src, 'Your organization type cannot control territories', 'error')
        return
    end
    
    -- Check territory exists
    local territory = MySQL.query.await('SELECT * FROM territories WHERE id = ?', {territoryId})
    if not territory or not territory[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Territory not found', 'error')
        return
    end
    
    -- Check if territory is already controlled by your org
    if territory[1].controlling_org_id == orgId then
        TriggerClientEvent('QBCore:Notify', src, 'Your organization already controls this territory', 'error')
        return
    end
    
    -- Check if there's an ongoing conflict
    local existingConflict = MySQL.query.await('SELECT id FROM territory_conflicts WHERE territory_id = ? AND status = ?',
        {territoryId, 'ongoing'})
    if existingConflict and existingConflict[1] then
        TriggerClientEvent('QBCore:Notify', src, 'There is already an ongoing conflict for this territory', 'error')
        return
    end
    
    -- Start the conflict
    MySQL.insert('INSERT INTO territory_conflicts (territory_id, attacker_org_id, defender_org_id, status) VALUES (?, ?, ?, ?)',
        {territoryId, orgId, territory[1].controlling_org_id, 'ongoing'})
    
    LogAction(orgId, citizenid, 'start_conflict', nil, json.encode({territory = territoryId}))
    
    TriggerClientEvent('QBCore:Notify', src, 'Territory conflict started for ' .. territory[1].name, 'success')
    
    -- Notify all players about the conflict
    TriggerClientEvent('client:org:conflictStarted', -1, territoryId, territory[1].name)
end)

-- Resolve a territory conflict
RegisterNetEvent('server:org:resolveConflict', function(conflictId, winnerId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    -- This would typically be called by game logic after a conflict mini-game
    -- For now, allow boss/executive to manually resolve
    
    local orgId, role = GetPlayerOrganization(citizenid)
    
    if not orgId then
        TriggerClientEvent('QBCore:Notify', src, 'You are not in an organization', 'error')
        return
    end
    
    local conflict = MySQL.query.await('SELECT * FROM territory_conflicts WHERE id = ? AND status = ?', {conflictId, 'ongoing'})
    if not conflict or not conflict[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Conflict not found or already resolved', 'error')
        return
    end
    
    -- Verify the player's org is involved
    if conflict[1].attacker_org_id ~= orgId and conflict[1].defender_org_id ~= orgId then
        TriggerClientEvent('QBCore:Notify', src, 'Your organization is not involved in this conflict', 'error')
        return
    end
    
    local status = 'attacker_win'
    if winnerId == conflict[1].defender_org_id then
        status = 'defender_win'
    end
    
    -- Update conflict status
    MySQL.query.await('UPDATE territory_conflicts SET status = ?, ended_at = NOW() WHERE id = ?', {status, conflictId})
    
    -- Update territory control if attacker won
    if status == 'attacker_win' then
        MySQL.query.await('UPDATE territories SET controlling_org_id = ? WHERE id = ?',
            {conflict[1].attacker_org_id, conflict[1].territory_id})
    end
    
    local territory = MySQL.query.await('SELECT name FROM territories WHERE id = ?', {conflict[1].territory_id})
    local territoryName = territory and territory[1] and territory[1].name or 'Unknown'
    
    LogAction(orgId, citizenid, 'resolve_conflict', nil, json.encode({conflict = conflictId, winner = winnerId}))
    
    TriggerClientEvent('QBCore:Notify', src, 'Conflict resolved for ' .. territoryName, 'success')
    TriggerClientEvent('client:org:conflictResolved', -1, conflictId, winnerId, territoryName)
end)

-- =====================================
-- CALLBACKS
-- =====================================

QBCore.Functions.CreateCallback('qb_org:server:getOrganization', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb(nil)
        return
    end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    if not orgId then
        cb(nil)
        return
    end
    
    local org = MySQL.query.await('SELECT * FROM organizations WHERE id = ?', {orgId})
    if org and org[1] then
        org[1].playerRole = role
        cb(org[1])
    else
        cb(nil)
    end
end)

QBCore.Functions.CreateCallback('qb_org:server:getMembers', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local orgId, _ = GetPlayerOrganization(citizenid)
    if not orgId then
        cb({})
        return
    end
    
    local members = MySQL.query.await([[
        SELECT om.*, p.charinfo 
        FROM organization_members om
        LEFT JOIN players p ON om.citizenid = p.citizenid
        WHERE om.org_id = ?
        ORDER BY 
            CASE om.role 
                WHEN 'boss' THEN 1 
                WHEN 'executive' THEN 2 
                WHEN 'member' THEN 3 
                WHEN 'associate' THEN 4 
            END
    ]], {orgId})
    
    -- Check online status
    for i, member in ipairs(members) do
        local player = QBCore.Functions.GetPlayerByCitizenId(member.citizenid)
        members[i].online = player ~= nil
        if member.charinfo then
            local charinfo = json.decode(member.charinfo)
            members[i].name = charinfo.firstname .. ' ' .. charinfo.lastname
        end
    end
    
    cb(members or {})
end)

QBCore.Functions.CreateCallback('qb_org:server:getAssets', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    if not orgId then
        cb({})
        return
    end
    
    -- Only show hidden assets if user has permission
    local showHidden = HasPermission(role, 'manageAssets')
    
    local query = 'SELECT * FROM org_assets WHERE org_id = ?'
    if not showHidden then
        query = query .. ' AND hidden = FALSE'
    end
    
    local assets = MySQL.query.await(query, {orgId})
    cb(assets or {})
end)

QBCore.Functions.CreateCallback('qb_org:server:getHiddenAccounts', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    local accounts = {}
    
    -- Get player's personal hidden accounts
    local playerAccounts = MySQL.query.await('SELECT * FROM hidden_accounts WHERE owner_type = ? AND owner_id = ?',
        {'player', citizenid})
    if playerAccounts then
        for _, acc in ipairs(playerAccounts) do
            acc.ownerName = 'Personal'
            table.insert(accounts, acc)
        end
    end
    
    -- Get organization hidden accounts if player has permission
    if orgId and HasPermission(role, 'manageAssets') then
        local orgAccounts = MySQL.query.await('SELECT * FROM hidden_accounts WHERE owner_type = ? AND owner_id = ?',
            {'organization', tostring(orgId)})
        if orgAccounts then
            for _, acc in ipairs(orgAccounts) do
                acc.ownerName = 'Organization'
                table.insert(accounts, acc)
            end
        end
    end
    
    cb(accounts)
end)

QBCore.Functions.CreateCallback('qb_org:server:getTerritories', function(source, cb)
    local territories = MySQL.query.await([[
        SELECT t.*, o.name as controller_name 
        FROM territories t
        LEFT JOIN organizations o ON t.controlling_org_id = o.id
    ]])
    cb(territories or {})
end)

QBCore.Functions.CreateCallback('qb_org:server:getOrgTerritories', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local orgId, _ = GetPlayerOrganization(citizenid)
    if not orgId then
        cb({})
        return
    end
    
    local territories = MySQL.query.await('SELECT * FROM territories WHERE controlling_org_id = ?', {orgId})
    cb(territories or {})
end)

QBCore.Functions.CreateCallback('qb_org:server:getLogs', function(source, cb, limit)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local orgId, role = GetPlayerOrganization(citizenid)
    if not orgId then
        cb({})
        return
    end
    
    if not HasPermission(role, 'viewLogs') then
        cb({})
        return
    end
    
    limit = limit or Config.NUI.maxLogEntries
    
    local logs = MySQL.query.await('SELECT * FROM org_logs WHERE org_id = ? ORDER BY created_at DESC LIMIT ?', {orgId, limit})
    cb(logs or {})
end)

-- =====================================
-- EXPORTS
-- =====================================

-- Export for other resources to get organization bonus for a player
exports('GetPlayerOrgBonus', function(citizenid, territoryId)
    local orgId, _ = GetPlayerOrganization(citizenid)
    if not orgId then return 1.0 end
    
    local territory = MySQL.query.await('SELECT base_bonus, controlling_org_id FROM territories WHERE id = ?', {territoryId})
    if territory and territory[1] and territory[1].controlling_org_id == orgId then
        return territory[1].base_bonus
    end
    
    return 1.0
end)

-- Export to get player's organization ID
exports('GetPlayerOrganization', function(citizenid)
    return GetPlayerOrganization(citizenid)
end)

-- Export to add revenue to organization
exports('AddOrgRevenue', function(orgId, amount, description)
    local asset = MySQL.query.await('SELECT id, amount FROM org_assets WHERE org_id = ? AND asset_type = ? AND identifier = ?',
        {orgId, 'cash', 'main_treasury'})
    
    if asset and asset[1] then
        MySQL.query.await('UPDATE org_assets SET amount = amount + ? WHERE id = ?', {amount, asset[1].id})
    else
        MySQL.insert('INSERT INTO org_assets (org_id, asset_type, identifier, amount, hidden) VALUES (?, ?, ?, ?, ?)',
            {orgId, 'cash', 'main_treasury', amount, false})
    end
    
    -- Log the revenue
    MySQL.insert('INSERT INTO org_logs (org_id, action_type, actor_cid, details) VALUES (?, ?, ?, ?)',
        {orgId, 'revenue', 'SYSTEM', json.encode({amount = amount, description = description})})
end)

-- =====================================
-- INITIALIZATION
-- =====================================

-- Initialize territories from config if they don't exist
CreateThread(function()
    Wait(1000) -- Wait for database connection
    
    for _, territory in ipairs(Config.Territories) do
        local existing = MySQL.query.await('SELECT id FROM territories WHERE zone_id = ?', {territory.id})
        if not existing or not existing[1] then
            MySQL.insert('INSERT INTO territories (name, zone_id, base_bonus) VALUES (?, ?, ?)',
                {territory.name, territory.id, territory.baseBonus})
            print('[org_system] Initialized territory: ' .. territory.name)
        end
    end
    
    print('[org_system] Server initialized')
end)
