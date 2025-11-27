--[[
    Resource: economy_system
    File: server/main.lua
    Purpose: Server-side logic for Criminal Economy System
    
    Responsibilities:
    - Manage criminal activities (start, progress, finish)
    - Dynamic market price calculation
    - Reward distribution with org integration
    - Police confiscation handling
    - Cooldown management
    
    Database tables used:
    - criminal_activities
    - market_index
    - activity_logs
    - player_cooldowns
    
    Events:
    - server:economy:startActivity
    - server:economy:finishActivity
    - server:economy:policeConfiscate
    - server:economy:launderMoney
    
    Callbacks:
    - qb_economy:server:getActivities
    - qb_economy:server:getMarketData
    - qb_economy:server:getPlayerStats
]]

local QBCore = exports['qb-core']:GetCoreObject()

-- Cache for market data
local MarketCache = {}
local CooldownCache = {}
local ActiveActivities = {}

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

local function GetActivityConfig(activityId)
    for _, activity in ipairs(Config.Activities) do
        if activity.id == activityId then
            return activity
        end
    end
    return nil
end

local function CheckPlayerHasItems(source, items)
    if not items or #items == 0 then return true end
    
    for _, itemName in ipairs(items) do
        local item = exports['ox_inventory']:Search(source, 'count', itemName)
        if not item or item < 1 then
            return false, itemName
        end
    end
    return true
end

local function GetNearbyPlayers(source, radius)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        if tonumber(playerId) ~= src then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(coords - targetCoords)
            
            if distance <= radius then
                table.insert(players, playerId)
            end
        end
    end
    
    return players
end

local function IsOnCooldown(citizenid, activityId)
    -- Check cache first
    local cacheKey = citizenid .. '_' .. activityId
    if CooldownCache[cacheKey] then
        if CooldownCache[cacheKey] > os.time() then
            return true, CooldownCache[cacheKey] - os.time()
        else
            CooldownCache[cacheKey] = nil
        end
    end
    
    -- Check database
    local result = MySQL.query.await('SELECT expires_at FROM player_cooldowns WHERE citizenid = ? AND activity_id = ? AND expires_at > NOW()', 
        {citizenid, activityId})
    
    if result and result[1] then
        local expiresAt = result[1].expires_at
        -- Parse datetime and convert to timestamp
        local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
        local year, month, day, hour, min, sec = expiresAt:match(pattern)
        if year then
            local expires = os.time({year=year, month=month, day=day, hour=hour, min=min, sec=sec})
            CooldownCache[cacheKey] = expires
            return true, expires - os.time()
        end
    end
    
    return false, 0
end

local function SetCooldown(citizenid, activityId, duration)
    local expiresAt = os.time() + duration
    local cacheKey = citizenid .. '_' .. activityId
    CooldownCache[cacheKey] = expiresAt
    
    MySQL.query.await('INSERT INTO player_cooldowns (citizenid, activity_id, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND)) ON DUPLICATE KEY UPDATE expires_at = DATE_ADD(NOW(), INTERVAL ? SECOND)',
        {citizenid, activityId, duration, duration})
end

-- =====================================
-- MARKET FUNCTIONS
-- =====================================

local function GetMarketPriceIndex(commodity)
    if MarketCache[commodity] then
        return MarketCache[commodity].price_index
    end
    
    local result = MySQL.query.await('SELECT price_index FROM market_index WHERE commodity = ?', {commodity})
    if result and result[1] then
        return result[1].price_index
    end
    
    return 1.0
end

local function UpdateMarketPrice(commodity, supplyChange, confiscationChange)
    -- Get current market data
    local result = MySQL.query.await('SELECT * FROM market_index WHERE commodity = ?', {commodity})
    
    local currentSupply = 0
    local currentConfiscation = 0
    local currentPriceIndex = 1.0
    
    if result and result[1] then
        currentSupply = result[1].server_supply
        currentConfiscation = result[1].confiscated_amount
        currentPriceIndex = result[1].price_index
    end
    
    -- Update supply and confiscation
    local newSupply = math.max(0, currentSupply + supplyChange)
    local newConfiscation = math.max(0, currentConfiscation + confiscationChange)
    
    -- Calculate new price index
    -- Higher supply = lower price, higher confiscation = higher price
    local supplyEffect = newSupply * Config.Market.supplyMultiplier
    local confiscationEffect = newConfiscation * Config.Market.confiscationMultiplier
    
    local newPriceIndex = 1.0 - supplyEffect + confiscationEffect
    newPriceIndex = math.max(Config.Market.minPriceMultiplier, math.min(Config.Market.maxPriceMultiplier, newPriceIndex))
    
    -- Update database
    MySQL.query.await([[
        INSERT INTO market_index (commodity, price_index, server_supply, confiscated_amount) 
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
            price_index = VALUES(price_index),
            server_supply = VALUES(server_supply),
            confiscated_amount = VALUES(confiscated_amount),
            last_updated = NOW()
    ]], {commodity, newPriceIndex, newSupply, newConfiscation})
    
    -- Update cache
    MarketCache[commodity] = {
        price_index = newPriceIndex,
        server_supply = newSupply,
        confiscated_amount = newConfiscation
    }
    
    return newPriceIndex
end

local function GetBasePrice(commodity)
    return Config.Market.basePrice[commodity] or 100
end

local function CalculateActualPrice(commodity)
    local basePrice = GetBasePrice(commodity)
    local priceIndex = GetMarketPriceIndex(commodity)
    return math.floor(basePrice * priceIndex)
end

-- =====================================
-- ACTIVITY MANAGEMENT
-- =====================================

-- Start an activity
RegisterNetEvent('server:economy:startActivity', function(activityId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Error: Could not verify player identity', 'error')
        return
    end
    
    -- Get activity configuration
    local activity = GetActivityConfig(activityId)
    if not activity then
        TriggerClientEvent('QBCore:Notify', src, 'Activity not found', 'error')
        return
    end
    
    -- Check cooldown
    local onCooldown, remaining = IsOnCooldown(citizenid, activityId)
    if onCooldown then
        local minutes = math.ceil(remaining / 60)
        TriggerClientEvent('QBCore:Notify', src, 'Activity on cooldown for ' .. minutes .. ' more minutes', 'error')
        return
    end
    
    -- Check required players
    if activity.requiredPlayers > 1 then
        local nearbyPlayers = GetNearbyPlayers(src, 50.0)
        if #nearbyPlayers + 1 < activity.requiredPlayers then
            TriggerClientEvent('QBCore:Notify', src, 'Need ' .. activity.requiredPlayers .. ' players for this activity', 'error')
            return
        end
    end
    
    -- Check required equipment
    local hasItems, missingItem = CheckPlayerHasItems(src, activity.requiredEquipment)
    if not hasItems then
        TriggerClientEvent('QBCore:Notify', src, 'Missing required equipment: ' .. missingItem, 'error')
        return
    end
    
    -- Start the activity
    ActiveActivities[citizenid] = {
        activityId = activityId,
        startTime = os.time(),
        activity = activity
    }
    
    TriggerClientEvent('QBCore:Notify', src, 'Started: ' .. activity.name, 'success')
    TriggerClientEvent('client:economy:activityStarted', src, activityId, activity)
    
    -- Check for police alert based on risk level
    local alertChance = Config.Risk.policeAlertChance[activity.riskLevel] or 0.1
    if math.random() < alertChance then
        -- Alert police
        TriggerEvent('server:economy:alertPolice', src, activity)
    end
end)

-- Finish an activity
RegisterNetEvent('server:economy:finishActivity', function(activityId, success)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    local activeActivity = ActiveActivities[citizenid]
    if not activeActivity or activeActivity.activityId ~= activityId then
        TriggerClientEvent('QBCore:Notify', src, 'No active activity found', 'error')
        return
    end
    
    local activity = activeActivity.activity
    ActiveActivities[citizenid] = nil
    
    -- Set cooldown
    SetCooldown(citizenid, activityId, activity.cooldown)
    
    if not success then
        TriggerClientEvent('QBCore:Notify', src, 'Activity failed', 'error')
        
        -- Log failed activity
        MySQL.insert('INSERT INTO activity_logs (citizenid, activity_id, activity_type, reward_amount, success) VALUES (?, ?, ?, ?, ?)',
            {citizenid, activityId, activity.type, 0, false})
        return
    end
    
    -- Calculate reward
    local baseReward = math.random(activity.baseRewardMin, activity.baseRewardMax)
    
    -- Apply market price index
    local priceIndex = 1.0
    if activity.commodity then
        priceIndex = GetMarketPriceIndex(activity.commodity)
    end
    
    -- Get organization bonus
    local territoryBonus = 1.0
    local orgId = nil
    local orgShare = 0
    local playerShare = baseReward
    
    -- Check if player is in an organization
    local playerOrgId, playerRole = exports['org_system']:GetPlayerOrganization(citizenid)
    if playerOrgId then
        orgId = playerOrgId
        
        -- Apply organization base bonus
        if Config.OrgBonus.baseOrgBonus > 1.0 then
            baseReward = math.floor(baseReward * Config.OrgBonus.baseOrgBonus)
        end
        
        -- Get territory bonus
        if Config.OrgBonus.territoryBonusEnabled then
            local currentTerritory = exports['org_system']:GetPlayerOrgBonus(citizenid, nil)
            if currentTerritory and currentTerritory > 1.0 then
                territoryBonus = math.min(currentTerritory, Config.OrgBonus.maxTerritoryBonus)
                baseReward = math.floor(baseReward * territoryBonus)
            end
        end
        
        -- Get member share percentage
        local memberData = MySQL.query.await('SELECT share_percent FROM organization_members WHERE org_id = ? AND citizenid = ?', {orgId, citizenid})
        local sharePercent = 100
        if memberData and memberData[1] then
            sharePercent = memberData[1].share_percent
        end
        
        -- Calculate shares
        playerShare = math.floor(baseReward * (sharePercent / 100))
        orgShare = baseReward - playerShare
        
        -- Add org share to organization treasury
        if orgShare > 0 then
            exports['org_system']:AddOrgRevenue(orgId, orgShare, 'Criminal activity: ' .. activity.name)
        end
    end
    
    -- Final reward after market price
    local finalReward = math.floor(baseReward * priceIndex)
    playerShare = math.floor(playerShare * priceIndex)
    orgShare = math.floor(orgShare * priceIndex)
    
    -- Give player their share
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney('cash', playerShare, 'criminal_activity_' .. activityId)
    end
    
    -- Update market supply
    if activity.commodity and activity.supplyAmount then
        UpdateMarketPrice(activity.commodity, activity.supplyAmount, 0)
    end
    
    -- Log the activity
    MySQL.insert('INSERT INTO activity_logs (citizenid, org_id, activity_id, activity_type, reward_amount, org_share, player_share, market_price_index, territory_bonus, success) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {citizenid, orgId, activityId, activity.type, finalReward, orgShare, playerShare, priceIndex, territoryBonus, true})
    
    TriggerClientEvent('QBCore:Notify', src, 'Earned ¥' .. playerShare .. (orgShare > 0 and ' (Org: ¥' .. orgShare .. ')' or ''), 'success')
    TriggerClientEvent('client:economy:activityCompleted', src, activityId, playerShare, orgShare)
end)

-- Cancel an activity
RegisterNetEvent('server:economy:cancelActivity', function()
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if citizenid and ActiveActivities[citizenid] then
        ActiveActivities[citizenid] = nil
        TriggerClientEvent('QBCore:Notify', src, 'Activity cancelled', 'primary')
    end
end)

-- =====================================
-- POLICE CONFISCATION
-- =====================================

RegisterNetEvent('server:economy:policeConfiscate', function(commodity, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verify player is police
    if Player.PlayerData.job.name ~= 'police' then
        TriggerClientEvent('QBCore:Notify', src, 'Only police can confiscate items', 'error')
        return
    end
    
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then return end
    
    -- Update market with confiscation
    local newPriceIndex = UpdateMarketPrice(commodity, 0, amount)
    
    TriggerClientEvent('QBCore:Notify', src, 'Confiscated ' .. amount .. ' units. Market price updated.', 'success')
    
    -- Notify economy system of the confiscation
    print('[economy_system] Police confiscated ' .. amount .. ' units of ' .. commodity .. '. New price index: ' .. newPriceIndex)
end)

-- =====================================
-- POLICE ALERT
-- =====================================

RegisterNetEvent('server:economy:alertPolice', function(playerSource, activity)
    local ped = GetPlayerPed(playerSource)
    if not ped then return end
    
    local coords = GetEntityCoords(ped)
    
    -- Get all online police
    local Players = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(Players) do
        local TargetPlayer = QBCore.Functions.GetPlayer(playerId)
        if TargetPlayer and TargetPlayer.PlayerData.job.name == 'police' then
            TriggerClientEvent('client:economy:policeAlert', playerId, coords, activity.type, activity.name)
        end
    end
end)

-- =====================================
-- MONEY LAUNDERING
-- =====================================

RegisterNetEvent('server:economy:launderMoney', function(amount)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    amount = math.max(0, tonumber(amount) or 0)
    
    if amount < Config.Laundering.minAmount then
        TriggerClientEvent('QBCore:Notify', src, 'Minimum laundering amount is ¥' .. Config.Laundering.minAmount, 'error')
        return
    end
    
    if amount > Config.Laundering.maxAmount then
        TriggerClientEvent('QBCore:Notify', src, 'Maximum laundering amount is ¥' .. Config.Laundering.maxAmount, 'error')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player has dirty money (cash)
    if Player.PlayerData.money.cash < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough cash to launder', 'error')
        return
    end
    
    -- Calculate fee
    local fee = math.floor(amount * Config.Laundering.fee)
    local cleanAmount = amount - fee
    
    -- Remove dirty cash, add to bank
    Player.Functions.RemoveMoney('cash', amount, 'money_laundering')
    Player.Functions.AddMoney('bank', cleanAmount, 'money_laundering_clean')
    
    -- Increase risk level for player's hidden accounts
    MySQL.query.await('UPDATE hidden_accounts SET risk_level = risk_level + ? WHERE owner_type = ? AND owner_id = ?',
        {Config.Laundering.riskPerLaunder, 'player', citizenid})
    
    TriggerClientEvent('QBCore:Notify', src, 'Laundered ¥' .. amount .. ' (Fee: ¥' .. fee .. ', Clean: ¥' .. cleanAmount .. ')', 'success')
end)

-- =====================================
-- CALLBACKS
-- =====================================

QBCore.Functions.CreateCallback('qb_economy:server:getActivities', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    
    local activities = {}
    for _, activity in ipairs(Config.Activities) do
        local activityData = {
            id = activity.id,
            type = activity.type,
            name = activity.name,
            description = activity.description,
            location = activity.location,
            requiredPlayers = activity.requiredPlayers,
            requiredEquipment = activity.requiredEquipment,
            riskLevel = activity.riskLevel,
            cooldown = activity.cooldown,
            baseRewardMin = activity.baseRewardMin,
            baseRewardMax = activity.baseRewardMax
        }
        
        -- Check cooldown
        if citizenid then
            local onCooldown, remaining = IsOnCooldown(citizenid, activity.id)
            activityData.onCooldown = onCooldown
            activityData.cooldownRemaining = remaining
        end
        
        -- Get current market price for reward estimate
        if activity.commodity then
            local priceIndex = GetMarketPriceIndex(activity.commodity)
            activityData.estimatedRewardMin = math.floor(activity.baseRewardMin * priceIndex)
            activityData.estimatedRewardMax = math.floor(activity.baseRewardMax * priceIndex)
        else
            activityData.estimatedRewardMin = activity.baseRewardMin
            activityData.estimatedRewardMax = activity.baseRewardMax
        end
        
        table.insert(activities, activityData)
    end
    
    cb(activities)
end)

QBCore.Functions.CreateCallback('qb_economy:server:getMarketData', function(source, cb)
    local marketData = {}
    
    for commodity, basePrice in pairs(Config.Market.basePrice) do
        local result = MySQL.query.await('SELECT * FROM market_index WHERE commodity = ?', {commodity})
        
        local data = {
            commodity = commodity,
            basePrice = basePrice,
            priceIndex = 1.0,
            currentPrice = basePrice,
            serverSupply = 0,
            confiscatedAmount = 0
        }
        
        if result and result[1] then
            data.priceIndex = result[1].price_index
            data.currentPrice = math.floor(basePrice * result[1].price_index)
            data.serverSupply = result[1].server_supply
            data.confiscatedAmount = result[1].confiscated_amount
        end
        
        table.insert(marketData, data)
    end
    
    cb(marketData)
end)

QBCore.Functions.CreateCallback('qb_economy:server:getPlayerStats', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    if not citizenid then
        cb(nil)
        return
    end
    
    -- Get activity stats
    local stats = MySQL.query.await([[
        SELECT 
            activity_type,
            COUNT(*) as total_activities,
            SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as successful,
            SUM(player_share) as total_earned
        FROM activity_logs
        WHERE citizenid = ?
        GROUP BY activity_type
    ]], {citizenid})
    
    -- Get total earnings
    local totals = MySQL.query.await([[
        SELECT 
            SUM(player_share) as total_earned,
            SUM(org_share) as total_org_contribution,
            COUNT(*) as total_activities
        FROM activity_logs
        WHERE citizenid = ? AND success = 1
    ]], {citizenid})
    
    cb({
        byType = stats or {},
        totals = totals and totals[1] or {total_earned = 0, total_org_contribution = 0, total_activities = 0}
    })
end)

-- =====================================
-- EXPORTS
-- =====================================

exports('GetMarketPrice', function(commodity)
    return CalculateActualPrice(commodity)
end)

exports('UpdateMarketSupply', function(commodity, amount)
    return UpdateMarketPrice(commodity, amount, 0)
end)

exports('PoliceConfiscate', function(commodity, amount)
    return UpdateMarketPrice(commodity, 0, amount)
end)

-- =====================================
-- INITIALIZATION
-- =====================================

CreateThread(function()
    Wait(1000)
    
    -- Initialize market index for all commodities
    for commodity, _ in pairs(Config.Market.basePrice) do
        local existing = MySQL.query.await('SELECT id FROM market_index WHERE commodity = ?', {commodity})
        if not existing or not existing[1] then
            MySQL.insert('INSERT INTO market_index (commodity, price_index, server_supply, confiscated_amount) VALUES (?, ?, ?, ?)',
                {commodity, 1.0, 0, 0})
        end
    end
    
    -- Load market cache
    local marketData = MySQL.query.await('SELECT * FROM market_index')
    if marketData then
        for _, data in ipairs(marketData) do
            MarketCache[data.commodity] = {
                price_index = data.price_index,
                server_supply = data.server_supply,
                confiscated_amount = data.confiscated_amount
            }
        end
    end
    
    print('[economy_system] Server initialized with ' .. #Config.Activities .. ' activities')
end)

-- Market update thread
CreateThread(function()
    while true do
        Wait(Config.Market.updateInterval * 1000)
        
        -- Natural supply decay (simulates consumption)
        for commodity, data in pairs(MarketCache) do
            if data.server_supply > 0 then
                local decay = math.max(1, math.floor(data.server_supply * 0.05))
                UpdateMarketPrice(commodity, -decay, 0)
            end
        end
        
        print('[economy_system] Market prices updated')
    end
end)

-- Cooldown cleanup thread
CreateThread(function()
    while true do
        Wait(300000) -- Every 5 minutes
        
        MySQL.query.await('DELETE FROM player_cooldowns WHERE expires_at < NOW()')
        
        -- Clean up cache
        local currentTime = os.time()
        for key, expiresAt in pairs(CooldownCache) do
            if expiresAt < currentTime then
                CooldownCache[key] = nil
            end
        end
    end
end)
