--[[
    Resource: police_system
    File: config.lua
    Purpose: Configuration settings for the Police & Justice System
    
    Contains:
    - Case status definitions
    - Evidence types
    - Punishment settings
    - Job permissions
]]

Config = {}

-- Authorized Jobs
Config.AuthorizedJobs = {
    police = {
        label = 'Police Department',
        canCreateCase = true,
        canAddEvidence = true,
        canVehicleCheck = true,
        canPersonLookup = true,
        canArrest = true,
        canConfiscate = true
    },
    doj = {
        label = 'Department of Justice',
        canViewCases = true,
        canProsecute = true,
        canDismiss = true,
        canSentence = true,
        canSeizeAssets = true
    }
}

-- Case Status Options
Config.CaseStatus = {
    ['open'] = {
        label = 'Open',
        color = '#4caf50',
        icon = 'fa-folder-open'
    },
    ['pending_prosecution'] = {
        label = 'Pending Prosecution',
        color = '#ff9800',
        icon = 'fa-gavel'
    },
    ['closed'] = {
        label = 'Closed',
        color = '#9e9e9e',
        icon = 'fa-folder'
    },
    ['dismissed'] = {
        label = 'Dismissed',
        color = '#f44336',
        icon = 'fa-times-circle'
    }
}

-- Suspect/Witness/Victim Roles
Config.PersonRoles = {
    ['suspect'] = {
        label = 'Suspect',
        color = '#f44336'
    },
    ['witness'] = {
        label = 'Witness',
        color = '#2196f3'
    },
    ['victim'] = {
        label = 'Victim',
        color = '#ff9800'
    }
}

-- Evidence Types
Config.EvidenceTypes = {
    ['item'] = {
        label = 'Physical Item',
        icon = 'fa-box'
    },
    ['weapon'] = {
        label = 'Weapon',
        icon = 'fa-gun'
    },
    ['photo'] = {
        label = 'Photograph',
        icon = 'fa-camera'
    },
    ['audio'] = {
        label = 'Audio Recording',
        icon = 'fa-microphone'
    },
    ['log'] = {
        label = 'Log/Report',
        icon = 'fa-file-alt'
    },
    ['dna'] = {
        label = 'DNA Sample',
        icon = 'fa-dna'
    },
    ['fingerprint'] = {
        label = 'Fingerprint',
        icon = 'fa-fingerprint'
    }
}

-- Punishment Settings
Config.Punishments = {
    jailTimeMultiplier = 1.0, -- Multiplier for jail time in minutes
    fineMultiplier = 1.0, -- Multiplier for fines
    maxJailTime = 120, -- Maximum jail time in minutes
    maxFine = 500000 -- Maximum fine amount
}

-- Case Generation Settings
Config.CaseNumber = {
    prefix = 'CASE',
    yearFormat = true, -- Include year in case number
    separator = '-'
}

-- Vehicle Check Settings
Config.VehicleCheck = {
    cacheTime = 300, -- Cache vehicle info for 5 minutes
    showPreviousCases = true,
    showOwnerInfo = true
}

-- Person Lookup Settings
Config.PersonLookup = {
    showLicenses = true,
    showCriminalHistory = true,
    showActiveCases = true,
    showOrganization = true
}

-- NUI Settings
Config.NUI = {
    defaultTab = 'cases',
    maxLogEntries = 50,
    refreshInterval = 30000
}
