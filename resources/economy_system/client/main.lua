--[[
    Resource: economy_system
    File: client/main.lua
    Purpose: Client-side logic for Criminal Economy System
    
    Responsibilities:
    - Handle activity UI
    - Activity progress tracking
    - Mini-game integration
    - Police alert display
    - Blip and marker management
    
    Events:
    - client:economy:openUI
    - client:economy:activityStarted
    - client:economy:activityCompleted
    - client:economy:policeAlert
]]

local QBCore = exports['qb-core']:GetCoreObject()

local isUIOpen = false
local currentActivity = nil
local activityBlips = {}
local policeAlertBlips = {}

-- =====================================
-- NUI FUNCTIONS
-- =====================================

local function OpenEconomyUI()
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = Config
    })
    
    RefreshEconomyData()
end

local function CloseEconomyUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

function RefreshEconomyData()
    -- Get activities
    QBCore.Functions.TriggerCallback('qb_economy:server:getActivities', function(activities)
        SendNUIMessage({
            action = 'setActivities',
            activities = activities
        })
    end)
    
    -- Get market data
    QBCore.Functions.TriggerCallback('qb_economy:server:getMarketData', function(marketData)
        SendNUIMessage({
            action = 'setMarketData',
            marketData = marketData
        })
    end)
    
    -- Get player stats
    QBCore.Functions.TriggerCallback('qb_economy:server:getPlayerStats', function(stats)
        SendNUIMessage({
            action = 'setPlayerStats',
            stats = stats
        })
    end)
end

-- =====================================
-- NUI CALLBACKS
-- =====================================

RegisterNUICallback('close', function(data, cb)
    CloseEconomyUI()
    cb('ok')
end)

RegisterNUICallback('startActivity', function(data, cb)
    if currentActivity then
        QBCore.Functions.Notify('Already doing an activity', 'error')
        cb('error')
        return
    end
    
    TriggerServerEvent('server:economy:startActivity', data.activityId)
    cb('ok')
end)

RegisterNUICallback('cancelActivity', function(data, cb)
    if currentActivity then
        TriggerServerEvent('server:economy:cancelActivity')
        currentActivity = nil
    end
    cb('ok')
end)

RegisterNUICallback('launderMoney', function(data, cb)
    TriggerServerEvent('server:economy:launderMoney', data.amount)
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    RefreshEconomyData()
    cb('ok')
end)

-- =====================================
-- CLIENT EVENTS
-- =====================================

RegisterNetEvent('client:economy:openUI', function()
    OpenEconomyUI()
end)

RegisterNetEvent('client:economy:activityStarted', function(activityId, activity)
    currentActivity = {
        id = activityId,
        activity = activity,
        startTime = GetGameTimer()
    }
    
    -- Close UI when activity starts
    if isUIOpen then
        CloseEconomyUI()
    end
    
    -- Start activity progress
    StartActivityProgress(activity)
end)

RegisterNetEvent('client:economy:activityCompleted', function(activityId, playerShare, orgShare)
    currentActivity = nil
    
    -- Refresh UI if open
    if isUIOpen then
        RefreshEconomyData()
    end
end)

RegisterNetEvent('client:economy:policeAlert', function(coords, activityType, activityName)
    -- Show police alert blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Suspicious Activity: " .. activityName)
    EndTextCommandSetBlipName(blip)
    
    table.insert(policeAlertBlips, {blip = blip, time = GetGameTimer()})
    
    QBCore.Functions.Notify('Suspicious activity reported: ' .. activityName, 'error', 5000)
    
    -- Play alert sound
    PlaySoundFrontend(-1, "LOSE_1ST", "PLACE_MISSION_CRATE_SOUNDS", true)
    
    -- Remove blip after duration
    SetTimeout(Config.Risk.policeBlipDuration, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

-- =====================================
-- ACTIVITY PROGRESS
-- =====================================

function StartActivityProgress(activity)
    -- Create progress bar
    QBCore.Functions.Progressbar('criminal_activity', 'Performing: ' .. activity.name, 30000, false, true, {
        disableMovement = false,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
        animDict = 'mini@repair',
        anim = 'fixing_a_ped',
        flags = 49
    }, {}, {}, function() -- Success
        -- Complete the activity
        TriggerServerEvent('server:economy:finishActivity', activity.id, true)
    end, function() -- Cancel
        TriggerServerEvent('server:economy:finishActivity', activity.id, false)
    end)
end

-- =====================================
-- ACTIVITY BLIPS
-- =====================================

local function CreateActivityBlips()
    for _, activity in ipairs(Config.Activities) do
        if activity.coords then
            local blip = AddBlipForCoord(activity.coords.x, activity.coords.y, activity.coords.z)
            
            -- Set blip sprite based on activity type
            local sprite = 1
            if activity.type == 'drug' then
                sprite = 51
            elseif activity.type == 'weapon' then
                sprite = 110
            elseif activity.type == 'fraud' then
                sprite = 431
            elseif activity.type == 'laundry' then
                sprite = 207
            else
                sprite = 378
            end
            
            SetBlipSprite(blip, sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.7)
            SetBlipColour(blip, 4) -- Yellow for criminal activities
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(activity.name)
            EndTextCommandSetBlipName(blip)
            
            activityBlips[activity.id] = blip
        end
    end
end

local function RemoveActivityBlips()
    for id, blip in pairs(activityBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    activityBlips = {}
end

-- =====================================
-- KEY BINDINGS
-- =====================================

RegisterCommand('crimemenu', function()
    OpenEconomyUI()
end, false)

RegisterKeyMapping('crimemenu', 'Open Criminal Activities Menu', 'keyboard', 'F7')

-- =====================================
-- EXPORTS
-- =====================================

exports('GetCurrentActivity', function()
    return currentActivity
end)

exports('IsDoingActivity', function()
    return currentActivity ~= nil
end)

-- =====================================
-- INITIALIZATION
-- =====================================

CreateThread(function()
    Wait(2000)
    CreateActivityBlips()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveActivityBlips()
        
        for _, blipData in ipairs(policeAlertBlips) do
            if DoesBlipExist(blipData.blip) then
                RemoveBlip(blipData.blip)
            end
        end
    end
end)

-- =====================================
-- KEYBOARD HANDLER
-- =====================================

CreateThread(function()
    while true do
        Wait(0)
        
        if IsControlJustReleased(0, 322) then -- ESC key
            if isUIOpen then
                CloseEconomyUI()
            end
        end
    end
end)
