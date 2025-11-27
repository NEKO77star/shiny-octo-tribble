--[[
    Resource: org_system
    File: config.lua
    Purpose: Configuration settings for the Organization & Territory System
    
    Contains:
    - Organization types and their settings
    - Role definitions and permissions
    - Territory zone definitions
    - Default salary and share settings
]]

Config = {}

-- Organization Types
Config.OrgTypes = {
    ['mafia'] = {
        label = 'Mafia',
        maxMembers = 50,
        canOwnTerritory = true,
        criminalOrg = true
    },
    ['gang'] = {
        label = 'Gang',
        maxMembers = 30,
        canOwnTerritory = true,
        criminalOrg = true
    },
    ['company'] = {
        label = 'Company',
        maxMembers = 100,
        canOwnTerritory = false,
        criminalOrg = false
    },
    ['store'] = {
        label = 'Store',
        maxMembers = 20,
        canOwnTerritory = false,
        criminalOrg = false
    }
}

-- Organization Roles with Default Settings
Config.Roles = {
    ['boss'] = {
        label = 'Boss',
        level = 4,
        defaultSalary = 10000,
        defaultShare = 40,
        permissions = {
            invite = true,
            kick = true,
            promote = true,
            demote = true,
            manageAssets = true,
            manageTerritories = true,
            editSettings = true,
            viewLogs = true
        }
    },
    ['executive'] = {
        label = 'Executive',
        level = 3,
        defaultSalary = 7500,
        defaultShare = 25,
        permissions = {
            invite = true,
            kick = true,
            promote = true,
            demote = true,
            manageAssets = true,
            manageTerritories = true,
            editSettings = false,
            viewLogs = true
        }
    },
    ['member'] = {
        label = 'Member',
        level = 2,
        defaultSalary = 5000,
        defaultShare = 20,
        permissions = {
            invite = false,
            kick = false,
            promote = false,
            demote = false,
            manageAssets = false,
            manageTerritories = false,
            editSettings = false,
            viewLogs = false
        }
    },
    ['associate'] = {
        label = 'Associate',
        level = 1,
        defaultSalary = 2500,
        defaultShare = 15,
        permissions = {
            invite = false,
            kick = false,
            promote = false,
            demote = false,
            manageAssets = false,
            manageTerritories = false,
            editSettings = false,
            viewLogs = false
        }
    }
}

-- Asset Types
Config.AssetTypes = {
    ['cash'] = { label = 'Cash', icon = 'fa-money-bill' },
    ['item'] = { label = 'Item', icon = 'fa-box' },
    ['property'] = { label = 'Property', icon = 'fa-building' },
    ['vehicle'] = { label = 'Vehicle', icon = 'fa-car' }
}

-- Currency Types for Hidden Accounts
Config.CurrencyTypes = {
    ['yen'] = { label = 'Yen', symbol = '¥' },
    ['crypto'] = { label = 'Cryptocurrency', symbol = '₿' }
}

-- Territory Settings
Config.TerritorySettings = {
    conflictCooldown = 86400, -- 24 hours in seconds
    minInfluenceToControl = 100,
    influenceDecayRate = 5, -- points per hour
    maxConflictDuration = 7200, -- 2 hours in seconds
}

-- Territory Zones (PolyZone compatible)
Config.Territories = {
    {
        id = 'little_tokyo',
        name = 'Little Tokyo',
        zone = {
            points = {
                vector2(-753.0, -950.0),
                vector2(-753.0, -750.0),
                vector2(-553.0, -750.0),
                vector2(-553.0, -950.0)
            },
            minZ = 20.0,
            maxZ = 100.0
        },
        baseBonus = 1.2
    },
    {
        id = 'port_district',
        name = 'Port District',
        zone = {
            points = {
                vector2(200.0, -3000.0),
                vector2(200.0, -2600.0),
                vector2(600.0, -2600.0),
                vector2(600.0, -3000.0)
            },
            minZ = -5.0,
            maxZ = 50.0
        },
        baseBonus = 1.15
    },
    {
        id = 'entertainment_district',
        name = 'Entertainment District',
        zone = {
            points = {
                vector2(100.0, -1000.0),
                vector2(100.0, -800.0),
                vector2(300.0, -800.0),
                vector2(300.0, -1000.0)
            },
            minZ = 28.0,
            maxZ = 80.0
        },
        baseBonus = 1.25
    }
}

-- NUI Settings
Config.NUI = {
    defaultTab = 'settings',
    refreshInterval = 30000, -- 30 seconds
    maxLogEntries = 100
}
