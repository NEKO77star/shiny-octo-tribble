--[[
    Resource: police_system
    File: server/main.lua
    Purpose: Server-side logic for Police & Justice System
    
    Responsibilities:
    - Case management (create, update, close)
    - Evidence management
    - Vehicle and person lookups
    - Prosecution and court proceedings
    - Warrant management
    - Criminal record management
    
    Database tables used:
    - cases
    - case_suspects
    - evidence
    - vehicle_checks
    - criminal_records
    - warrants
    
    Events:
    - server:police:createCase
    - server:police:updateCaseStatus
    - server:police:addSuspect
    - server:police:addEvidence
    - server:police:prosecuteCase
    - server:police:sentenceCase
    
    Callbacks:
    - qb_police:server:getCases
    - qb_police:server:getCaseDetails
    - qb_police:server:vehicleCheck
    - qb_police:server:personLookup
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

local function GetPlayerJob(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.job.name
    end
    return nil
end

local function IsAuthorized(source, permission)
    local job = GetPlayerJob(source)
    if not job or not Config.AuthorizedJobs[job] then
        return false
    end
    return Config.AuthorizedJobs[job][permission] == true
end

local function GenerateCaseNumber()
    local year = os.date('%Y')
    local result = MySQL.query.await('SELECT MAX(id) as max_id FROM cases')
    local nextId = (result and result[1] and result[1].max_id or 0) + 1
    
    return Config.CaseNumber.prefix .. Config.CaseNumber.separator .. year .. Config.CaseNumber.separator .. string.format('%05d', nextId)
end

local function GetPlayerName(citizenid)
    local result = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
    if result and result[1] and result[1].charinfo then
        local charinfo = json.decode(result[1].charinfo)
        return charinfo.firstname .. ' ' .. charinfo.lastname
    end
    return 'Unknown'
end

-- =====================================
-- CASE MANAGEMENT
-- =====================================

-- Create a new case
RegisterNetEvent('server:police:createCase', function(title, description)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'Error: Could not verify identity', 'error')
        return
    end
    
    if not IsAuthorized(src, 'canCreateCase') then
        TriggerClientEvent('QBCore:Notify', src, 'You are not authorized to create cases', 'error')
        return
    end
    
    local caseNumber = GenerateCaseNumber()
    
    local caseId = MySQL.insert.await('INSERT INTO cases (case_number, title, description, lead_officer_cid) VALUES (?, ?, ?, ?)',
        {caseNumber, title, description, citizenid})
    
    if caseId then
        TriggerClientEvent('QBCore:Notify', src, 'Case ' .. caseNumber .. ' created', 'success')
        TriggerClientEvent('client:police:caseCreated', src, caseId, caseNumber)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Failed to create case', 'error')
    end
end)

-- Update case status
RegisterNetEvent('server:police:updateCaseStatus', function(caseId, newStatus)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    local job = GetPlayerJob(src)
    
    if not citizenid then return end
    
    -- Check permissions based on status change
    if newStatus == 'pending_prosecution' then
        if not IsAuthorized(src, 'canCreateCase') then
            TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
            return
        end
    elseif newStatus == 'closed' or newStatus == 'dismissed' then
        if not IsAuthorized(src, 'canProsecute') then
            TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
            return
        end
    end
    
    local closedAt = nil
    if newStatus == 'closed' or newStatus == 'dismissed' then
        closedAt = os.date('%Y-%m-%d %H:%M:%S')
    end
    
    MySQL.query.await('UPDATE cases SET status = ?, closed_at = ? WHERE id = ?', {newStatus, closedAt, caseId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Case status updated to ' .. Config.CaseStatus[newStatus].label, 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- Add suspect/witness/victim to case
RegisterNetEvent('server:police:addPerson', function(caseId, targetCitizenId, role, notes)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canCreateCase') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    -- Check if person already exists in case with same role
    local existing = MySQL.query.await('SELECT id FROM case_suspects WHERE case_id = ? AND citizenid = ? AND role = ?',
        {caseId, targetCitizenId, role})
    
    if existing and existing[1] then
        TriggerClientEvent('QBCore:Notify', src, 'This person is already added as ' .. role, 'error')
        return
    end
    
    MySQL.insert('INSERT INTO case_suspects (case_id, citizenid, role, notes, added_by_cid) VALUES (?, ?, ?, ?, ?)',
        {caseId, targetCitizenId, role, notes, citizenid})
    
    local roleLabel = Config.PersonRoles[role] and Config.PersonRoles[role].label or role
    TriggerClientEvent('QBCore:Notify', src, roleLabel .. ' added to case', 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- Remove person from case
RegisterNetEvent('server:police:removePerson', function(caseId, personId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canCreateCase') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    MySQL.query.await('DELETE FROM case_suspects WHERE id = ? AND case_id = ?', {personId, caseId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Person removed from case', 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- Add evidence to case
RegisterNetEvent('server:police:addEvidence', function(caseId, evidenceType, referenceId, description)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canAddEvidence') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    MySQL.insert('INSERT INTO evidence (case_id, evidence_type, reference_id, description, seized_by_cid) VALUES (?, ?, ?, ?, ?)',
        {caseId, evidenceType, referenceId, description, citizenid})
    
    TriggerClientEvent('QBCore:Notify', src, 'Evidence added to case', 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- Remove evidence from case
RegisterNetEvent('server:police:removeEvidence', function(caseId, evidenceId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canAddEvidence') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    MySQL.query.await('DELETE FROM evidence WHERE id = ? AND case_id = ?', {evidenceId, caseId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Evidence removed', 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- =====================================
-- PROSECUTION & SENTENCING
-- =====================================

-- Accept case for prosecution
RegisterNetEvent('server:police:acceptProsecution', function(caseId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canProsecute') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    MySQL.query.await('UPDATE cases SET prosecutor_cid = ? WHERE id = ? AND status = ?',
        {citizenid, caseId, 'pending_prosecution'})
    
    TriggerClientEvent('QBCore:Notify', src, 'You are now the prosecutor for this case', 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- Sentence a case
RegisterNetEvent('server:police:sentenceCase', function(caseId, jailTime, fine, notes)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canSentence') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    -- Validate amounts
    jailTime = math.min(Config.Punishments.maxJailTime, math.max(0, tonumber(jailTime) or 0))
    fine = math.min(Config.Punishments.maxFine, math.max(0, tonumber(fine) or 0))
    
    -- Update case
    MySQL.query.await([[
        UPDATE cases 
        SET status = 'closed', 
            judge_cid = ?,
            sentence_jail_time = ?,
            sentence_fine = ?,
            sentence_notes = ?,
            closed_at = NOW()
        WHERE id = ?
    ]], {citizenid, jailTime, fine, notes, caseId})
    
    -- Get suspects and apply sentence
    local suspects = MySQL.query.await('SELECT citizenid FROM case_suspects WHERE case_id = ? AND role = ?', {caseId, 'suspect'})
    
    if suspects then
        for _, suspect in ipairs(suspects) do
            -- Add criminal record
            local caseInfo = MySQL.query.await('SELECT case_number, title FROM cases WHERE id = ?', {caseId})
            if caseInfo and caseInfo[1] then
                MySQL.insert('INSERT INTO criminal_records (citizenid, case_id, offense, sentence, fine, officer_cid, notes) VALUES (?, ?, ?, ?, ?, ?, ?)',
                    {suspect.citizenid, caseId, caseInfo[1].title, jailTime .. ' minutes jail', fine, citizenid, notes})
            end
            
            -- Apply jail time if player is online
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(suspect.citizenid)
            if targetPlayer then
                if jailTime > 0 then
                    -- This would trigger jail system - implementation depends on jail resource
                    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source, 
                        'You have been sentenced to ' .. jailTime .. ' minutes in prison', 'error')
                end
                
                if fine > 0 then
                    targetPlayer.Functions.RemoveMoney('bank', fine, 'court_fine_case_' .. caseId)
                    TriggerClientEvent('QBCore:Notify', targetPlayer.PlayerData.source,
                        'You have been fined ¥' .. fine, 'error')
                end
            end
        end
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Sentence applied successfully', 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- Dismiss case
RegisterNetEvent('server:police:dismissCase', function(caseId, reason)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canDismiss') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    MySQL.query.await('UPDATE cases SET status = ?, sentence_notes = ?, closed_at = NOW() WHERE id = ?',
        {'dismissed', reason, caseId})
    
    TriggerClientEvent('QBCore:Notify', src, 'Case dismissed', 'success')
    TriggerClientEvent('client:police:caseUpdated', src, caseId)
end)

-- =====================================
-- VEHICLE CHECK
-- =====================================

RegisterNetEvent('server:police:vehicleCheck', function(plate)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canVehicleCheck') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    plate = string.upper(plate)
    
    -- Get vehicle info
    local vehicleInfo = MySQL.query.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    
    local result = {
        plate = plate,
        found = false,
        owner = nil,
        model = nil,
        cases = {}
    }
    
    if vehicleInfo and vehicleInfo[1] then
        result.found = true
        result.owner = {
            citizenid = vehicleInfo[1].citizenid,
            name = GetPlayerName(vehicleInfo[1].citizenid)
        }
        result.model = vehicleInfo[1].vehicle
        
        -- Get related cases
        if Config.VehicleCheck.showPreviousCases then
            local cases = MySQL.query.await([[
                SELECT DISTINCT c.id, c.case_number, c.title, c.status
                FROM cases c
                JOIN case_suspects cs ON c.id = cs.case_id
                WHERE cs.citizenid = ?
                ORDER BY c.created_at DESC
                LIMIT 10
            ]], {vehicleInfo[1].citizenid})
            
            result.cases = cases or {}
        end
    end
    
    -- Log the vehicle check
    MySQL.insert('INSERT INTO vehicle_checks (plate, owner_cid, owner_name, vehicle_model, checked_by_cid) VALUES (?, ?, ?, ?, ?)',
        {plate, result.owner and result.owner.citizenid, result.owner and result.owner.name, result.model, citizenid})
    
    TriggerClientEvent('client:police:vehicleCheckResult', src, result)
end)

-- =====================================
-- PERSON LOOKUP
-- =====================================

RegisterNetEvent('server:police:personLookup', function(searchQuery)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canPersonLookup') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    -- Search by citizenid or name
    local results = MySQL.query.await([[
        SELECT citizenid, charinfo, metadata
        FROM players
        WHERE citizenid = ? OR charinfo LIKE ?
        LIMIT 10
    ]], {searchQuery, '%' .. searchQuery .. '%'})
    
    local persons = {}
    
    if results then
        for _, row in ipairs(results) do
            local charinfo = json.decode(row.charinfo) or {}
            local metadata = json.decode(row.metadata) or {}
            
            local person = {
                citizenid = row.citizenid,
                name = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or ''),
                phone = charinfo.phone or 'Unknown',
                birthdate = charinfo.birthdate or 'Unknown',
                licenses = metadata.licences or {}
            }
            
            -- Get criminal history
            if Config.PersonLookup.showCriminalHistory then
                local records = MySQL.query.await('SELECT * FROM criminal_records WHERE citizenid = ? ORDER BY date DESC LIMIT 10',
                    {row.citizenid})
                person.criminalHistory = records or {}
            end
            
            -- Get active cases
            if Config.PersonLookup.showActiveCases then
                local cases = MySQL.query.await([[
                    SELECT c.id, c.case_number, c.title, c.status, cs.role
                    FROM cases c
                    JOIN case_suspects cs ON c.id = cs.case_id
                    WHERE cs.citizenid = ? AND c.status IN ('open', 'pending_prosecution')
                ]], {row.citizenid})
                person.activeCases = cases or {}
            end
            
            -- Get warrants
            local warrants = MySQL.query.await('SELECT * FROM warrants WHERE citizenid = ? AND status = ?',
                {row.citizenid, 'active'})
            person.activeWarrants = warrants or {}
            
            table.insert(persons, person)
        end
    end
    
    TriggerClientEvent('client:police:personLookupResult', src, persons)
end)

-- =====================================
-- WARRANTS
-- =====================================

RegisterNetEvent('server:police:issueWarrant', function(targetCitizenId, warrantType, reason, caseId)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canProsecute') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    MySQL.insert('INSERT INTO warrants (citizenid, case_id, type, reason, issued_by_cid) VALUES (?, ?, ?, ?, ?)',
        {targetCitizenId, caseId, warrantType, reason, citizenid})
    
    TriggerClientEvent('QBCore:Notify', src, 'Warrant issued successfully', 'success')
    
    -- Notify all police
    local Players = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(Players) do
        local TargetPlayer = QBCore.Functions.GetPlayer(playerId)
        if TargetPlayer and TargetPlayer.PlayerData.job.name == 'police' then
            local targetName = GetPlayerName(targetCitizenId)
            TriggerClientEvent('QBCore:Notify', playerId, 
                (warrantType == 'arrest' and 'Arrest' or 'Search') .. ' warrant issued for ' .. targetName, 'primary')
        end
    end
end)

-- =====================================
-- CONFISCATION
-- =====================================

RegisterNetEvent('server:police:confiscateItem', function(commodity, amount)
    local src = source
    local citizenid = GetPlayerCitizenId(src)
    
    if not citizenid then return end
    
    if not IsAuthorized(src, 'canConfiscate') then
        TriggerClientEvent('QBCore:Notify', src, 'Not authorized', 'error')
        return
    end
    
    -- Update market prices via economy_system
    TriggerEvent('server:economy:policeConfiscate', commodity, amount)
    
    TriggerClientEvent('QBCore:Notify', src, 'Items confiscated and logged', 'success')
end)

-- =====================================
-- CALLBACKS
-- =====================================

QBCore.Functions.CreateCallback('qb_police:server:getCases', function(source, cb, status, page, perPage)
    local citizenid = GetPlayerCitizenId(source)
    local job = GetPlayerJob(source)
    
    if not citizenid or not Config.AuthorizedJobs[job] then
        cb({cases = {}, total = 0})
        return
    end
    
    page = page or 1
    perPage = perPage or 20
    local offset = (page - 1) * perPage
    
    local whereClause = ''
    local params = {}
    
    if status and status ~= 'all' then
        whereClause = 'WHERE status = ?'
        table.insert(params, status)
    end
    
    -- Count total
    local countResult = MySQL.query.await('SELECT COUNT(*) as total FROM cases ' .. whereClause, params)
    local total = countResult and countResult[1] and countResult[1].total or 0
    
    -- Get cases
    table.insert(params, perPage)
    table.insert(params, offset)
    
    local cases = MySQL.query.await([[
        SELECT c.*, 
            (SELECT COUNT(*) FROM case_suspects WHERE case_id = c.id) as person_count,
            (SELECT COUNT(*) FROM evidence WHERE case_id = c.id) as evidence_count
        FROM cases c
        ]] .. whereClause .. [[
        ORDER BY c.created_at DESC
        LIMIT ? OFFSET ?
    ]], params)
    
    -- Add officer names
    if cases then
        for i, case in ipairs(cases) do
            cases[i].lead_officer_name = GetPlayerName(case.lead_officer_cid)
            if case.prosecutor_cid then
                cases[i].prosecutor_name = GetPlayerName(case.prosecutor_cid)
            end
        end
    end
    
    cb({cases = cases or {}, total = total})
end)

QBCore.Functions.CreateCallback('qb_police:server:getCaseDetails', function(source, cb, caseId)
    local citizenid = GetPlayerCitizenId(source)
    local job = GetPlayerJob(source)
    
    if not citizenid or not Config.AuthorizedJobs[job] then
        cb(nil)
        return
    end
    
    -- Get case
    local caseResult = MySQL.query.await('SELECT * FROM cases WHERE id = ?', {caseId})
    if not caseResult or not caseResult[1] then
        cb(nil)
        return
    end
    
    local caseData = caseResult[1]
    caseData.lead_officer_name = GetPlayerName(caseData.lead_officer_cid)
    if caseData.prosecutor_cid then
        caseData.prosecutor_name = GetPlayerName(caseData.prosecutor_cid)
    end
    if caseData.judge_cid then
        caseData.judge_name = GetPlayerName(caseData.judge_cid)
    end
    
    -- Get persons
    local persons = MySQL.query.await('SELECT * FROM case_suspects WHERE case_id = ?', {caseId})
    if persons then
        for i, person in ipairs(persons) do
            persons[i].name = GetPlayerName(person.citizenid)
        end
    end
    caseData.persons = persons or {}
    
    -- Get evidence
    local evidence = MySQL.query.await('SELECT * FROM evidence WHERE case_id = ?', {caseId})
    if evidence then
        for i, ev in ipairs(evidence) do
            evidence[i].seized_by_name = GetPlayerName(ev.seized_by_cid)
        end
    end
    caseData.evidence = evidence or {}
    
    cb(caseData)
end)

QBCore.Functions.CreateCallback('qb_police:server:getStats', function(source, cb)
    local citizenid = GetPlayerCitizenId(source)
    
    if not citizenid then
        cb(nil)
        return
    end
    
    local stats = {
        openCases = 0,
        pendingCases = 0,
        closedCases = 0,
        myCases = 0
    }
    
    local counts = MySQL.query.await([[
        SELECT status, COUNT(*) as count FROM cases GROUP BY status
    ]])
    
    if counts then
        for _, row in ipairs(counts) do
            if row.status == 'open' then
                stats.openCases = row.count
            elseif row.status == 'pending_prosecution' then
                stats.pendingCases = row.count
            elseif row.status == 'closed' or row.status == 'dismissed' then
                stats.closedCases = stats.closedCases + row.count
            end
        end
    end
    
    local myCases = MySQL.query.await('SELECT COUNT(*) as count FROM cases WHERE lead_officer_cid = ?', {citizenid})
    stats.myCases = myCases and myCases[1] and myCases[1].count or 0
    
    cb(stats)
end)

-- =====================================
-- INITIALIZATION
-- =====================================

CreateThread(function()
    Wait(1000)
    print('[police_system] Server initialized')
end)
