--[[
    Resource: life_system
    File: client/main.lua
    Purpose: Client-side logic for Life & Roleplay System
    
    Responsibilities:
    - Phone UI integration
    - Property interaction
    - Legal job tasks
    - Hobby activities (fishing, gambling)
    
    Events:
    - client:life:openPhone
    - client:life:propertyPurchased
    - client:life:newMessage
    - client:life:snsPosted
]]

local QBCore = exports['qb-core']:GetCoreObject()

local isPhoneOpen = false
local currentProperty = nil
local isFishing = false

-- =====================================
-- PHONE FUNCTIONS
-- =====================================

local function OpenPhone()
    if isPhoneOpen then return end
    
    isPhoneOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = Config
    })
    
    RefreshPhoneData()
end

local function ClosePhone()
    if not isPhoneOpen then return end
    
    isPhoneOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

function RefreshPhoneData()
    -- Get messages/conversations
    QBCore.Functions.TriggerCallback('qb_life:server:getMessages', function(conversations)
        SendNUIMessage({
            action = 'setConversations',
            conversations = conversations
        })
    end)
    
    -- Get contacts
    QBCore.Functions.TriggerCallback('qb_life:server:getContacts', function(contacts)
        SendNUIMessage({
            action = 'setContacts',
            contacts = contacts
        })
    end)
    
    -- Get SNS feed
    QBCore.Functions.TriggerCallback('qb_life:server:getSNSFeed', function(posts)
        SendNUIMessage({
            action = 'setSNSFeed',
            posts = posts
        })
    end)
    
    -- Get bank data
    QBCore.Functions.TriggerCallback('qb_life:server:getBankData', function(bankData)
        SendNUIMessage({
            action = 'setBankData',
            bankData = bankData
        })
    end)
    
    -- Get insurances
    QBCore.Functions.TriggerCallback('qb_life:server:getInsurances', function(insurances)
        SendNUIMessage({
            action = 'setInsurances',
            insurances = insurances
        })
    end)
end

-- =====================================
-- NUI CALLBACKS
-- =====================================

RegisterNUICallback('close', function(data, cb)
    ClosePhone()
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('server:life:sendMessage', data.receiverCid, data.message)
    cb('ok')
end)

RegisterNUICallback('getConversation', function(data, cb)
    QBCore.Functions.TriggerCallback('qb_life:server:getConversation', function(messages)
        cb(messages)
    end, data.otherCid)
end)

RegisterNUICallback('markMessagesRead', function(data, cb)
    TriggerServerEvent('server:life:markMessagesRead', data.otherCid)
    cb('ok')
end)

RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('server:life:addContact', data.citizenid, data.name)
    Wait(500)
    RefreshPhoneData()
    cb('ok')
end)

RegisterNUICallback('removeContact', function(data, cb)
    TriggerServerEvent('server:life:removeContact', data.contactId)
    Wait(500)
    RefreshPhoneData()
    cb('ok')
end)

RegisterNUICallback('postSNS', function(data, cb)
    TriggerServerEvent('server:life:postSNS', data.content, data.imageUrl, data.visibility)
    Wait(500)
    RefreshPhoneData()
    cb('ok')
end)

RegisterNUICallback('likeSNSPost', function(data, cb)
    TriggerServerEvent('server:life:likeSNSPost', data.postId)
    cb('ok')
end)

RegisterNUICallback('purchaseInsurance', function(data, cb)
    TriggerServerEvent('server:life:purchaseInsurance', data.insuranceType, data.targetId, data.premium)
    Wait(500)
    RefreshPhoneData()
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    RefreshPhoneData()
    cb('ok')
end)

-- =====================================
-- CLIENT EVENTS
-- =====================================

RegisterNetEvent('client:life:openPhone', function()
    OpenPhone()
end)

RegisterNetEvent('client:life:newMessage', function(senderCid, senderName, message)
    QBCore.Functions.Notify('New message from ' .. senderName, 'primary', 5000)
    
    if isPhoneOpen then
        RefreshPhoneData()
    end
end)

RegisterNetEvent('client:life:snsPosted', function()
    if isPhoneOpen then
        RefreshPhoneData()
    end
end)

RegisterNetEvent('client:life:propertyPurchased', function(propertyId)
    QBCore.Functions.Notify('Property purchased successfully!', 'success')
end)

RegisterNetEvent('client:life:propertyRented', function(propertyId)
    QBCore.Functions.Notify('Property rented successfully!', 'success')
end)

-- =====================================
-- PROPERTY BLIPS AND MARKERS
-- =====================================

local propertyBlips = {}

local function CreatePropertyBlips()
    for _, property in ipairs(Config.Properties) do
        local blip = AddBlipForCoord(property.coords.x, property.coords.y, property.coords.z)
        
        local sprite = 40 -- default house
        if property.type == 'office' then
            sprite = 475
        elseif property.type == 'shop' then
            sprite = 52
        elseif property.type == 'gang_hideout' then
            sprite = 84
        end
        
        SetBlipSprite(blip, sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2) -- green
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(property.name)
        EndTextCommandSetBlipName(blip)
        
        propertyBlips[property.id] = blip
    end
end

-- =====================================
-- FISHING SYSTEM
-- =====================================

local function StartFishing()
    if isFishing then return end
    
    isFishing = true
    
    -- Animation
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_STAND_FISHING", 0, true)
    
    QBCore.Functions.Notify('Fishing... Wait for a bite!', 'primary')
    
    -- Random fishing time (5-15 seconds)
    local fishingTime = math.random(5000, 15000)
    
    CreateThread(function()
        Wait(fishingTime)
        
        if not isFishing then return end
        
        -- Determine catch based on rarity
        local roll = math.random()
        local cumulative = 0
        local caught = nil
        
        for _, fish in ipairs(Config.Fishing.fish) do
            cumulative = cumulative + fish.rarity
            if roll <= cumulative then
                caught = fish
                break
            end
        end
        
        -- Stop animation
        ClearPedTasks(playerPed)
        isFishing = false
        
        if caught then
            QBCore.Functions.Notify('Caught: ' .. caught.label .. ' (Worth ¥' .. caught.price .. ')', 'success')
            TriggerServerEvent('server:life:completeJob', 'fishing', caught.price)
        else
            QBCore.Functions.Notify('The fish got away!', 'error')
        end
    end)
end

local function StopFishing()
    if not isFishing then return end
    
    isFishing = false
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    QBCore.Functions.Notify('Stopped fishing', 'primary')
end

-- =====================================
-- KEY BINDINGS
-- =====================================

RegisterCommand('phone', function()
    OpenPhone()
end, false)

RegisterKeyMapping('phone', 'Open Phone', 'keyboard', 'F1')

RegisterCommand('fish', function()
    -- Check if near fishing spot
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearSpot = false
    
    for _, spot in ipairs(Config.Fishing.spots) do
        if #(playerCoords - spot.coords) < 10.0 then
            nearSpot = true
            break
        end
    end
    
    if nearSpot then
        if isFishing then
            StopFishing()
        else
            StartFishing()
        end
    else
        QBCore.Functions.Notify('You need to be near a fishing spot', 'error')
    end
end, false)

-- =====================================
-- EXPORTS
-- =====================================

exports('OpenPhone', function()
    OpenPhone()
end)

exports('IsPhoneOpen', function()
    return isPhoneOpen
end)

exports('IsFishing', function()
    return isFishing
end)

-- =====================================
-- INITIALIZATION
-- =====================================

CreateThread(function()
    Wait(2000)
    CreatePropertyBlips()
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, blip in pairs(propertyBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        
        if isFishing then
            StopFishing()
        end
    end
end)

-- Keyboard handler
CreateThread(function()
    while true do
        Wait(0)
        
        if IsControlJustReleased(0, 322) then -- ESC key
            if isPhoneOpen then
                ClosePhone()
            end
        end
    end
end)
