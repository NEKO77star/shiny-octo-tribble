--[[
    Resource: org_system
    File: client/main.lua
    Purpose: Client-side logic for Organization & Territory System
    
    Responsibilities:
    - Handle NUI communication
    - Manage organization UI state
    - Territory zone detection and display
    - Client-side event handling
    
    Events:
    - client:org:openUI
    - client:org:updateOrgUI
    - client:org:organizationDisbanded
    - client:org:conflictStarted
    - client:org:conflictResolved
]]

local QBCore = exports['qb-core']:GetCoreObject()

local isUIOpen = false
local currentOrganization = nil
local currentTerritory = nil

-- =====================================
-- NUI FUNCTIONS
-- =====================================

local function OpenOrgUI()
    if isUIOpen then return end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = Config
    })
    
    -- Fetch initial data
    RefreshOrgData()
end

local function CloseOrgUI()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

function RefreshOrgData()
    -- Get organization data
    QBCore.Functions.TriggerCallback('qb_org:server:getOrganization', function(org)
        currentOrganization = org
        SendNUIMessage({
            action = 'setOrganization',
            organization = org
        })
        
        if org then
            -- Get members
            QBCore.Functions.TriggerCallback('qb_org:server:getMembers', function(members)
                SendNUIMessage({
                    action = 'setMembers',
                    members = members
                })
            end)
            
            -- Get assets
            QBCore.Functions.TriggerCallback('qb_org:server:getAssets', function(assets)
                SendNUIMessage({
                    action = 'setAssets',
                    assets = assets
                })
            end)
            
            -- Get hidden accounts
            QBCore.Functions.TriggerCallback('qb_org:server:getHiddenAccounts', function(accounts)
                SendNUIMessage({
                    action = 'setHiddenAccounts',
                    accounts = accounts
                })
            end)
            
            -- Get organization territories
            QBCore.Functions.TriggerCallback('qb_org:server:getOrgTerritories', function(territories)
                SendNUIMessage({
                    action = 'setTerritories',
                    territories = territories
                })
            end)
            
            -- Get logs
            QBCore.Functions.TriggerCallback('qb_org:server:getLogs', function(logs)
                SendNUIMessage({
                    action = 'setLogs',
                    logs = logs
                })
            end)
        end
    end)
end

-- =====================================
-- NUI CALLBACKS
-- =====================================

RegisterNUICallback('close', function(data, cb)
    CloseOrgUI()
    cb('ok')
end)

RegisterNUICallback('createOrganization', function(data, cb)
    TriggerServerEvent('server:org:createOrganization', data.name, data.type)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('disbandOrganization', function(data, cb)
    TriggerServerEvent('server:org:disbandOrganization', data.orgId)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('inviteMember', function(data, cb)
    TriggerServerEvent('server:org:inviteMember', data.citizenid)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('kickMember', function(data, cb)
    TriggerServerEvent('server:org:kickMember', data.citizenid)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('promoteMember', function(data, cb)
    TriggerServerEvent('server:org:promoteMember', data.citizenid)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('demoteMember', function(data, cb)
    TriggerServerEvent('server:org:demoteMember', data.citizenid)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('updateCompensation', function(data, cb)
    TriggerServerEvent('server:org:updateMemberCompensation', data.citizenid, data.salary, data.sharePercent)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('addAsset', function(data, cb)
    TriggerServerEvent('server:org:addAsset', data.assetType, data.identifier, data.amount, data.hidden)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('removeAsset', function(data, cb)
    TriggerServerEvent('server:org:removeAsset', data.assetId, data.amount)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('createHiddenAccount', function(data, cb)
    TriggerServerEvent('server:org:createHiddenAccount', data.ownerType, data.ownerId, data.currency)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('depositHiddenAccount', function(data, cb)
    TriggerServerEvent('server:org:depositHiddenAccount', data.accountId, data.amount)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('withdrawHiddenAccount', function(data, cb)
    TriggerServerEvent('server:org:withdrawHiddenAccount', data.accountId, data.amount)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('startConflict', function(data, cb)
    TriggerServerEvent('server:org:startConflict', data.territoryId)
    Wait(500)
    RefreshOrgData()
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    RefreshOrgData()
    cb('ok')
end)

-- =====================================
-- CLIENT EVENTS
-- =====================================

RegisterNetEvent('client:org:openUI', function()
    OpenOrgUI()
end)

RegisterNetEvent('client:org:updateOrgUI', function()
    if isUIOpen then
        RefreshOrgData()
    end
end)

RegisterNetEvent('client:org:organizationDisbanded', function(orgId)
    if currentOrganization and currentOrganization.id == orgId then
        currentOrganization = nil
        if isUIOpen then
            RefreshOrgData()
        end
    end
end)

RegisterNetEvent('client:org:conflictStarted', function(territoryId, territoryName)
    QBCore.Functions.Notify('Territory conflict started: ' .. territoryName, 'primary', 5000)
end)

RegisterNetEvent('client:org:conflictResolved', function(conflictId, winnerId, territoryName)
    QBCore.Functions.Notify('Territory conflict resolved: ' .. territoryName, 'success', 5000)
    if isUIOpen then
        RefreshOrgData()
    end
end)

-- =====================================
-- TERRITORY ZONES
-- =====================================

local territoryBlips = {}
local territoryZones = {}

local function CreateTerritoryBlip(territory)
    if not territory.zone or not territory.zone.points or #territory.zone.points < 1 then
        return
    end
    
    local centerX, centerY = 0, 0
    for _, point in ipairs(territory.zone.points) do
        centerX = centerX + point.x
        centerY = centerY + point.y
    end
    centerX = centerX / #territory.zone.points
    centerY = centerY / #territory.zone.points
    
    local blip = AddBlipForCoord(centerX, centerY, 0.0)
    SetBlipSprite(blip, 310)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(territory.name)
    EndTextCommandSetBlipName(blip)
    
    territoryBlips[territory.id] = blip
end

local function InitializeTerritoryZones()
    for _, territory in ipairs(Config.Territories) do
        CreateTerritoryBlip(territory)
    end
end

-- Check which territory the player is in
CreateThread(function()
    Wait(2000)
    InitializeTerritoryZones()
    
    while true do
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local newTerritory = nil
        
        for _, territory in ipairs(Config.Territories) do
            if territory.zone and territory.zone.points then
                local inZone = false
                local points = territory.zone.points
                local j = #points
                
                for i = 1, #points do
                    if ((points[i].y > coords.y) ~= (points[j].y > coords.y)) and
                       (coords.x < (points[j].x - points[i].x) * (coords.y - points[i].y) / (points[j].y - points[i].y) + points[i].x) then
                        inZone = not inZone
                    end
                    j = i
                end
                
                if inZone and coords.z >= territory.zone.minZ and coords.z <= territory.zone.maxZ then
                    newTerritory = territory
                    break
                end
            end
        end
        
        if newTerritory and (not currentTerritory or currentTerritory.id ~= newTerritory.id) then
            currentTerritory = newTerritory
            TriggerEvent('client:org:enteredTerritory', currentTerritory)
        elseif not newTerritory and currentTerritory then
            TriggerEvent('client:org:leftTerritory', currentTerritory)
            currentTerritory = nil
        end
        
        Wait(1000)
    end
end)

RegisterNetEvent('client:org:enteredTerritory', function(territory)
    QBCore.Functions.Notify('Entered territory: ' .. territory.name, 'primary', 3000)
end)

RegisterNetEvent('client:org:leftTerritory', function(territory)
    QBCore.Functions.Notify('Left territory: ' .. territory.name, 'primary', 3000)
end)

-- =====================================
-- KEY BINDINGS
-- =====================================

RegisterCommand('orgmenu', function()
    OpenOrgUI()
end, false)

RegisterKeyMapping('orgmenu', 'Open Organization Menu', 'keyboard', 'F6')

-- =====================================
-- EXPORTS
-- =====================================

exports('GetCurrentTerritory', function()
    return currentTerritory
end)

exports('GetCurrentOrganization', function()
    return currentOrganization
end)

exports('IsInOrganization', function()
    return currentOrganization ~= nil
end)
