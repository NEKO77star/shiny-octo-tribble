--[[
    Resource: life_system
    File: server/main.lua
    Purpose: Server-side logic for Life & Roleplay System
    
    Responsibilities:
    - Property management (buy, rent, sell)
    - Insurance management
    - Phone messaging system
    - SNS (social network) system
    - Legal jobs management
    
    Database tables used:
    - properties
    - insurances
    - phone_contacts
    - phone_messages
    - sns_posts
    - secure_chat_rooms
    - secure_chat_messages
    - job_completions
    
    Events:
    - server:life:buyProperty
    - server:life:rentProperty
    - server:life:purchaseInsurance
    - server:life:sendMessage
    - server:life:postSNS
    
    Callbacks:
    - qb_life:server:getProperties
    - qb_life:server:getInsurances
    - qb_life:server:getMessages
    - qb_life:server:getSNSFeed
]]

local QBCore = exports['qb-core']:GetCoreObject()

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

local function GetPlayerName(citizenid)
    local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
    if result and result[1] and result[1].charinfo then
        local charinfo = json.decode(result[1].charinfo)
        return charinfo.firstname .. ' ' .. charinfo.lastname
    end
    return 'Unknown'
end

local function GetPlayerPhone(citizenid)
    local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
    if result and result[1] and result[1].charinfo then
        local charinfo = json.decode(result[1].charinfo)
        return charinfo.phone or 'Unknown'
    end
    return 'Unknown'
end

-- =====================================
-- PROPERTY MANAGEMENT
-- =====================================

-- Buy a property
RegisterNetEvent('server:life:buyProperty', function(propertyId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Error: Could not verify identity', 'error')
        return
    end
    
    -- Get property info
    local property = MySQL.query.await('SELECT * FROM properties WHERE property_id = ?', {propertyId})
    
    if not property or not property[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Property not found', 'error')
        return
    end
    
    property = property[1]
    
    -- Check if already owned
    if property.owner_id then
        TriggerClientEvent('QBCore:Notify', src, 'This property is already owned', 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    local price = property.sale_price
    
    -- Check if player has enough money
    if Player.PlayerData.money.bank < price then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money in bank', 'error')
        return
    end
    
    -- Process purchase
    Player.Functions.RemoveMoney('bank', price, 'property_purchase_' .. propertyId)
    
    MySQL.query.await('UPDATE properties SET owner_type = ?, owner_id = ?, is_rent = ? WHERE property_id = ?',
        {'player', citizenid, false, propertyId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Property purchased successfully!', 'success')
    TriggerClientEvent('client:life:propertyPurchased', src, propertyId)
end)

-- Rent a property
RegisterNetEvent('server:life:rentProperty', function(propertyId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local property = MySQL.query.await('SELECT * FROM properties WHERE property_id = ?', {propertyId})
    
    if not property or not property[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Property not found', 'error')
        return
    end
    
    property = property[1]
    
    if property.owner_id then
        TriggerClientEvent('QBCore:Notify', src, 'This property is not available for rent', 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    local rentPrice = property.rent_price
    
    if Player.PlayerData.money.bank < rentPrice then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money in bank', 'error')
        return
    end
    
    Player.Functions.RemoveMoney('bank', rentPrice, 'property_rent_' .. propertyId)
    
    -- Rent for 30 days
    MySQL.query.await('UPDATE properties SET owner_type = ?, owner_id = ?, is_rent = ?, rent_expires_at = DATE_ADD(NOW(), INTERVAL 30 DAY) WHERE property_id = ?',
        {'player', citizenid, true, propertyId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Property rented for 30 days!', 'success')
    TriggerClientEvent('client:life:propertyRented', src, propertyId)
end)

-- Sell a property
RegisterNetEvent('server:life:sellProperty', function(propertyId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local property = MySQL.query.await('SELECT * FROM properties WHERE property_id = ? AND owner_id = ? AND is_rent = FALSE',
        {propertyId, citizenid})
    
    if not property or not property[1] then
        TriggerClientEvent('QBCore:Notify', src, 'You do not own this property', 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    local sellPrice = math.floor(property[1].sale_price * 0.7) -- 70% of purchase price
    
    Player.Functions.AddMoney('bank', sellPrice, 'property_sale_' .. propertyId)
    
    MySQL.query.await('UPDATE properties SET owner_type = NULL, owner_id = NULL, is_rent = FALSE, rent_expires_at = NULL WHERE property_id = ?',
        {propertyId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Property sold for ¥' .. sellPrice, 'success')
end)

-- =====================================
-- INSURANCE MANAGEMENT
-- =====================================

RegisterNetEvent('server:life:purchaseInsurance', function(insuranceType, targetId, premium)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local insuranceConfig = Config.InsuranceTypes[insuranceType]
    if not insuranceConfig then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid insurance type', 'error')
        return
    end
    
    premium = math.max(insuranceConfig.basePremium, tonumber(premium) or 0)
    local coverage = premium * insuranceConfig.coverageMultiplier
    
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.money.bank < premium then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money in bank', 'error')
        return
    end
    
    Player.Functions.RemoveMoney('bank', premium, 'insurance_' .. insuranceType)
    
    -- Check if insurance already exists
    local existing = MySQL.query.await('SELECT id FROM insurances WHERE type = ? AND target_id = ?', {insuranceType, targetId})
    
    if existing and existing[1] then
        -- Renew existing insurance
        MySQL.query.await('UPDATE insurances SET premium = ?, coverage = ?, valid_until = DATE_ADD(NOW(), INTERVAL ? DAY), owner_cid = ? WHERE id = ?',
            {premium, coverage, insuranceConfig.validityDays, citizenid, existing[1].id})
    else
        -- Create new insurance
        MySQL.insert('INSERT INTO insurances (type, target_id, owner_cid, premium, coverage, valid_until) VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))',
            {insuranceType, targetId, citizenid, premium, coverage, insuranceConfig.validityDays})
    end
    
    TriggerClientEvent('QBCore:Notify', src, insuranceConfig.label .. ' purchased! Coverage: ¥' .. coverage, 'success')
end)

-- =====================================
-- PHONE MESSAGING
-- =====================================

RegisterNetEvent('server:life:sendMessage', function(receiverCid, message)
    local src = source
    local senderCid = GetPlayerCitizenId(src)
    
    if not senderCid then return end
    
    MySQL.insert('INSERT INTO phone_messages (sender_cid, receiver_cid, message) VALUES (?, ?, ?)',
        {senderCid, receiverCid, message})
    
    -- Notify receiver if online
    local receiver = QBCore.Functions.GetPlayerByCitizenId(receiverCid)
    if receiver then
        local senderName = GetPlayerName(senderCid)
        TriggerClientEvent('client:life:newMessage', receiver.PlayerData.source, senderCid, senderName, message)
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Message sent', 'success')
end)

RegisterNetEvent('server:life:markMessagesRead', function(otherCid)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    MySQL.query.await('UPDATE phone_messages SET is_read = TRUE WHERE receiver_cid = ? AND sender_cid = ?',
        {citizenid, otherCid})
end)

-- =====================================
-- PHONE CONTACTS
-- =====================================

RegisterNetEvent('server:life:addContact', function(contactCid, contactName)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local contactNumber = GetPlayerPhone(contactCid)
    
    MySQL.query.await('INSERT INTO phone_contacts (owner_cid, contact_cid, contact_name, contact_number) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE contact_name = ?, contact_number = ?',
        {citizenid, contactCid, contactName, contactNumber, contactName, contactNumber})
    
    TriggerClientEvent('QBCore:Notify', src, 'Contact added', 'success')
end)

RegisterNetEvent('server:life:removeContact', function(contactId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    MySQL.query.await('DELETE FROM phone_contacts WHERE id = ? AND owner_cid = ?', {contactId, citizenid})
    
    TriggerClientEvent('QBCore:Notify', src, 'Contact removed', 'success')
end)

-- =====================================
-- SNS (SOCIAL NETWORK)
-- =====================================

RegisterNetEvent('server:life:postSNS', function(content, imageUrl, visibility)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local authorName = GetPlayerName(citizenid)
    local orgId = nil
    
    -- Get org ID if visibility is org-only
    if visibility == 'org' then
        local playerOrgId, _ = exports['org_system']:GetPlayerOrganization(citizenid)
        if playerOrgId then
            orgId = playerOrgId
        else
            visibility = 'public'
        end
    end
    
    MySQL.insert('INSERT INTO sns_posts (author_cid, author_name, content, image_url, visibility, org_id) VALUES (?, ?, ?, ?, ?, ?)',
        {citizenid, authorName, content, imageUrl, visibility, orgId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Posted to SNS', 'success')
    TriggerClientEvent('client:life:snsPosted', -1)
end)

RegisterNetEvent('server:life:likeSNSPost', function(postId)
    local src = source
    
    MySQL.query.await('UPDATE sns_posts SET likes = likes + 1 WHERE id = ?', {postId})
end)

-- =====================================
-- SECURE CHAT
-- =====================================

RegisterNetEvent('server:life:createSecureRoom', function(roomName, password)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    -- Check if room name exists
    local existing = MySQL.query.await('SELECT id FROM secure_chat_rooms WHERE room_name = ?', {roomName})
    if existing and existing[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Room name already exists', 'error')
        return
    end
    
    local orgId = nil
    local playerOrgId, _ = exports['org_system']:GetPlayerOrganization(citizenid)
    if playerOrgId then
        orgId = playerOrgId
    end
    
    MySQL.insert('INSERT INTO secure_chat_rooms (room_name, room_password, org_id, created_by_cid) VALUES (?, ?, ?, ?)',
        {roomName, password, orgId, citizenid})
    
    TriggerClientEvent('QBCore:Notify', src, 'Secure room created', 'success')
end)

RegisterNetEvent('server:life:sendSecureMessage', function(roomId, message, alias)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    MySQL.insert('INSERT INTO secure_chat_messages (room_id, sender_cid, sender_alias, message) VALUES (?, ?, ?, ?)',
        {roomId, citizenid, alias or 'Anonymous', message})
    
    -- Broadcast to online users in room
    TriggerClientEvent('client:life:secureMessageReceived', -1, roomId)
end)

-- =====================================
-- LEGAL JOBS
-- =====================================

RegisterNetEvent('server:life:completeJob', function(jobId, earnings)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney('cash', earnings, 'job_' .. jobId)
    
    -- Update job completions
    MySQL.query.await('INSERT INTO job_completions (citizenid, job_id, completions, total_earnings, last_completed_at) VALUES (?, ?, 1, ?, NOW()) ON DUPLICATE KEY UPDATE completions = completions + 1, total_earnings = total_earnings + ?, last_completed_at = NOW()',
        {citizenid, jobId, earnings, earnings})
    
    TriggerClientEvent('QBCore:Notify', src, 'Job completed! Earned ¥' .. earnings, 'success')
end)

-- =====================================
-- CALLBACKS
-- =====================================

QBCore.Functions.CreateCallback('qb_life:server:getProperties', function(source, cb, onlyOwned)
    local citizenid = GetPlayerCitizenId(source)
    
    local properties
    if onlyOwned and citizenid then
        properties = MySQL.query.await('SELECT * FROM properties WHERE owner_id = ?', {citizenid})
    else
        properties = MySQL.query.await('SELECT * FROM properties')
    end
    
    cb(properties or {})
end)

QBCore.Functions.CreateCallback('qb_life:server:getInsurances', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local insurances = MySQL.query.await('SELECT * FROM insurances WHERE owner_cid = ? AND valid_until > NOW()', {citizenid})
    cb(insurances or {})
end)

QBCore.Functions.CreateCallback('qb_life:server:getMessages', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    -- Get conversations
    local conversations = MySQL.query.await([[
        SELECT 
            CASE 
                WHEN sender_cid = ? THEN receiver_cid 
                ELSE sender_cid 
            END as other_cid,
            MAX(created_at) as last_message_at,
            SUM(CASE WHEN receiver_cid = ? AND is_read = FALSE THEN 1 ELSE 0 END) as unread_count
        FROM phone_messages
        WHERE sender_cid = ? OR receiver_cid = ?
        GROUP BY other_cid
        ORDER BY last_message_at DESC
    ]], {citizenid, citizenid, citizenid, citizenid})
    
    -- Add names
    if conversations then
        for i, conv in ipairs(conversations) do
            conversations[i].name = GetPlayerName(conv.other_cid)
            conversations[i].phone = GetPlayerPhone(conv.other_cid)
        end
    end
    
    cb(conversations or {})
end)

QBCore.Functions.CreateCallback('qb_life:server:getConversation', function(source, cb, otherCid)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local messages = MySQL.query.await([[
        SELECT * FROM phone_messages
        WHERE (sender_cid = ? AND receiver_cid = ?) OR (sender_cid = ? AND receiver_cid = ?)
        ORDER BY created_at ASC
        LIMIT 100
    ]], {citizenid, otherCid, otherCid, citizenid})
    
    cb(messages or {})
end)

QBCore.Functions.CreateCallback('qb_life:server:getContacts', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local contacts = MySQL.query.await('SELECT * FROM phone_contacts WHERE owner_cid = ? ORDER BY contact_name', {citizenid})
    cb(contacts or {})
end)

QBCore.Functions.CreateCallback('qb_life:server:getSNSFeed', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local orgId = nil
    local playerOrgId, _ = exports['org_system']:GetPlayerOrganization(citizenid)
    if playerOrgId then
        orgId = playerOrgId
    end
    
    local posts
    if orgId then
        posts = MySQL.query.await([[
            SELECT * FROM sns_posts 
            WHERE visibility = 'public' OR (visibility = 'org' AND org_id = ?) OR author_cid = ?
            ORDER BY created_at DESC
            LIMIT 50
        ]], {orgId, citizenid})
    else
        posts = MySQL.query.await([[
            SELECT * FROM sns_posts 
            WHERE visibility = 'public' OR author_cid = ?
            ORDER BY created_at DESC
            LIMIT 50
        ]], {citizenid})
    end
    
    cb(posts or {})
end)

QBCore.Functions.CreateCallback('qb_life:server:getBankData', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb(nil)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(nil)
        return
    end
    
    local bankData = {
        cash = Player.PlayerData.money.cash,
        bank = Player.PlayerData.money.bank,
        hiddenAccounts = {}
    }
    
    -- Get hidden accounts
    local hiddenAccounts = MySQL.query.await('SELECT * FROM hidden_accounts WHERE owner_type = ? AND owner_id = ?',
        {'player', citizenid})
    
    if hiddenAccounts then
        bankData.hiddenAccounts = hiddenAccounts
    end
    
    cb(bankData)
end)

QBCore.Functions.CreateCallback('qb_life:server:getJobStats', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb({})
        return
    end
    
    local stats = MySQL.query.await('SELECT * FROM job_completions WHERE citizenid = ?', {citizenid})
    cb(stats or {})
end)

-- =====================================
-- INITIALIZATION
-- =====================================

CreateThread(function()
    Wait(1000)
    
    -- Initialize properties from config if they don't exist
    for _, property in ipairs(Config.Properties) do
        local existing = MySQL.query.await('SELECT id FROM properties WHERE property_id = ?', {property.id})
        if not existing or not existing[1] then
            local coords = json.encode({x = property.coords.x, y = property.coords.y, z = property.coords.z})
            MySQL.insert('INSERT INTO properties (property_id, name, type, entrance_coords, interior_id, rent_price, sale_price) VALUES (?, ?, ?, ?, ?, ?, ?)',
                {property.id, property.name, property.type, coords, property.interior, property.rentPrice, property.salePrice})
            print('[life_system] Initialized property: ' .. property.name)
        end
    end
    
    print('[life_system] Server initialized')
end)

-- Rent expiry check thread
CreateThread(function()
    while true do
        Wait(3600000) -- Every hour
        
        -- Clear expired rentals
        MySQL.query.await('UPDATE properties SET owner_type = NULL, owner_id = NULL, is_rent = FALSE, rent_expires_at = NULL WHERE is_rent = TRUE AND rent_expires_at < NOW()')
    end
end)
