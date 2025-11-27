--[[
    Resource: police_system
    File: client/main.lua
    Purpose: Client-side logic for Police & Justice System
    
    Responsibilities:
    - Handle MDT UI
    - Vehicle and person lookup
    - Case management interface
    - Evidence collection
    
    Events:
    - client:police:openMDT
    - client:police:caseCreated
    - client:police:caseUpdated
    - client:police:vehicleCheckResult
    - client:police:personLookupResult
]]

local QBCore = exports['qb-core']:GetCoreObject()

local isUIOpen = false
local currentCases = {}
local currentCaseDetails = nil

-- =====================================
-- NUI FUNCTIONS
-- =====================================

local function OpenMDT()
    if isUIOpen then return end
    
    -- Check if player is authorized
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData.job or not Config.AuthorizedJobs[PlayerData.job.name] then
        QBCore.Functions.Notify('You are not authorized to use the MDT', 'error')
        return
    end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = Config,
        job = PlayerData.job.name
    })
    
    RefreshMDTData()
end

local function CloseMDT()
    if not isUIOpen then return end
    
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

function RefreshMDTData()
    -- Get cases
    QBCore.Functions.TriggerCallback('qb_police:server:getCases', function(data)
        SendNUIMessage({
            action = 'setCases',
            cases = data.cases,
            total = data.total
        })
    end, 'all', 1, 50)
    
    -- Get stats
    QBCore.Functions.TriggerCallback('qb_police:server:getStats', function(stats)
        SendNUIMessage({
            action = 'setStats',
            stats = stats
        })
    end)
end

function LoadCaseDetails(caseId)
    QBCore.Functions.TriggerCallback('qb_police:server:getCaseDetails', function(caseData)
        currentCaseDetails = caseData
        SendNUIMessage({
            action = 'setCaseDetails',
            caseData = caseData
        })
    end, caseId)
end

-- =====================================
-- NUI CALLBACKS
-- =====================================

RegisterNUICallback('close', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('createCase', function(data, cb)
    TriggerServerEvent('server:police:createCase', data.title, data.description)
    Wait(500)
    RefreshMDTData()
    cb('ok')
end)

RegisterNUICallback('getCaseDetails', function(data, cb)
    LoadCaseDetails(data.caseId)
    cb('ok')
end)

RegisterNUICallback('updateCaseStatus', function(data, cb)
    TriggerServerEvent('server:police:updateCaseStatus', data.caseId, data.status)
    Wait(500)
    LoadCaseDetails(data.caseId)
    cb('ok')
end)

RegisterNUICallback('addPerson', function(data, cb)
    TriggerServerEvent('server:police:addPerson', data.caseId, data.citizenid, data.role, data.notes)
    Wait(500)
    LoadCaseDetails(data.caseId)
    cb('ok')
end)

RegisterNUICallback('removePerson', function(data, cb)
    TriggerServerEvent('server:police:removePerson', data.caseId, data.personId)
    Wait(500)
    LoadCaseDetails(data.caseId)
    cb('ok')
end)

RegisterNUICallback('addEvidence', function(data, cb)
    TriggerServerEvent('server:police:addEvidence', data.caseId, data.evidenceType, data.referenceId, data.description)
    Wait(500)
    LoadCaseDetails(data.caseId)
    cb('ok')
end)

RegisterNUICallback('removeEvidence', function(data, cb)
    TriggerServerEvent('server:police:removeEvidence', data.caseId, data.evidenceId)
    Wait(500)
    LoadCaseDetails(data.caseId)
    cb('ok')
end)

RegisterNUICallback('acceptProsecution', function(data, cb)
    TriggerServerEvent('server:police:acceptProsecution', data.caseId)
    Wait(500)
    LoadCaseDetails(data.caseId)
    cb('ok')
end)

RegisterNUICallback('sentenceCase', function(data, cb)
    TriggerServerEvent('server:police:sentenceCase', data.caseId, data.jailTime, data.fine, data.notes)
    Wait(500)
    RefreshMDTData()
    cb('ok')
end)

RegisterNUICallback('dismissCase', function(data, cb)
    TriggerServerEvent('server:police:dismissCase', data.caseId, data.reason)
    Wait(500)
    RefreshMDTData()
    cb('ok')
end)

RegisterNUICallback('vehicleCheck', function(data, cb)
    TriggerServerEvent('server:police:vehicleCheck', data.plate)
    cb('ok')
end)

RegisterNUICallback('personLookup', function(data, cb)
    TriggerServerEvent('server:police:personLookup', data.query)
    cb('ok')
end)

RegisterNUICallback('issueWarrant', function(data, cb)
    TriggerServerEvent('server:police:issueWarrant', data.citizenid, data.warrantType, data.reason, data.caseId)
    Wait(500)
    cb('ok')
end)

RegisterNUICallback('filterCases', function(data, cb)
    QBCore.Functions.TriggerCallback('qb_police:server:getCases', function(caseData)
        SendNUIMessage({
            action = 'setCases',
            cases = caseData.cases,
            total = caseData.total
        })
    end, data.status, data.page, data.perPage)
    cb('ok')
end)

RegisterNUICallback('refreshData', function(data, cb)
    RefreshMDTData()
    cb('ok')
end)

-- =====================================
-- CLIENT EVENTS
-- =====================================

RegisterNetEvent('client:police:openMDT', function()
    OpenMDT()
end)

RegisterNetEvent('client:police:caseCreated', function(caseId, caseNumber)
    if isUIOpen then
        RefreshMDTData()
        LoadCaseDetails(caseId)
    end
end)

RegisterNetEvent('client:police:caseUpdated', function(caseId)
    if isUIOpen then
        RefreshMDTData()
        if currentCaseDetails and currentCaseDetails.id == caseId then
            LoadCaseDetails(caseId)
        end
    end
end)

RegisterNetEvent('client:police:vehicleCheckResult', function(result)
    SendNUIMessage({
        action = 'vehicleCheckResult',
        result = result
    })
end)

RegisterNetEvent('client:police:personLookupResult', function(persons)
    SendNUIMessage({
        action = 'personLookupResult',
        persons = persons
    })
end)

-- =====================================
-- KEY BINDINGS
-- =====================================

RegisterCommand('mdt', function()
    OpenMDT()
end, false)

RegisterKeyMapping('mdt', 'Open Police MDT', 'keyboard', 'F5')

-- =====================================
-- EXPORTS
-- =====================================

exports('OpenMDT', function()
    OpenMDT()
end)

exports('IsMDTOpen', function()
    return isUIOpen
end)

-- =====================================
-- KEYBOARD HANDLER
-- =====================================

CreateThread(function()
    while true do
        Wait(0)
        
        if IsControlJustReleased(0, 322) then -- ESC key
            if isUIOpen then
                CloseMDT()
            end
        end
    end
end)
