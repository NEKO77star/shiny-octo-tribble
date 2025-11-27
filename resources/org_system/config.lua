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
    -- Downtown Los Santos
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
    },
    -- Gang Territories
    {
        id = 'grove_street',
        name = 'Grove Street',
        zone = {
            points = {
                vector2(-200.0, -2000.0),
                vector2(-200.0, -1850.0),
                vector2(0.0, -1850.0),
                vector2(0.0, -2000.0)
            },
            minZ = 15.0,
            maxZ = 60.0
        },
        baseBonus = 1.3
    },
    {
        id = 'davis',
        name = 'Davis',
        zone = {
            points = {
                vector2(0.0, -2100.0),
                vector2(0.0, -1900.0),
                vector2(200.0, -1900.0),
                vector2(200.0, -2100.0)
            },
            minZ = 15.0,
            maxZ = 60.0
        },
        baseBonus = 1.25
    },
    {
        id = 'rancho',
        name = 'Rancho',
        zone = {
            points = {
                vector2(200.0, -2100.0),
                vector2(200.0, -1900.0),
                vector2(450.0, -1900.0),
                vector2(450.0, -2100.0)
            },
            minZ = 15.0,
            maxZ = 60.0
        },
        baseBonus = 1.2
    },
    {
        id = 'strawberry',
        name = 'Strawberry',
        zone = {
            points = {
                vector2(0.0, -1200.0),
                vector2(0.0, -1000.0),
                vector2(200.0, -1000.0),
                vector2(200.0, -1200.0)
            },
            minZ = 25.0,
            maxZ = 70.0
        },
        baseBonus = 1.15
    },
    -- Industrial Areas
    {
        id = 'la_mesa',
        name = 'La Mesa',
        zone = {
            points = {
                vector2(700.0, -2100.0),
                vector2(700.0, -1800.0),
                vector2(1100.0, -1800.0),
                vector2(1100.0, -2100.0)
            },
            minZ = 20.0,
            maxZ = 80.0
        },
        baseBonus = 1.1
    },
    {
        id = 'cypress_flats',
        name = 'Cypress Flats',
        zone = {
            points = {
                vector2(600.0, -1800.0),
                vector2(600.0, -1600.0),
                vector2(900.0, -1600.0),
                vector2(900.0, -1800.0)
            },
            minZ = 25.0,
            maxZ = 60.0
        },
        baseBonus = 1.1
    },
    {
        id = 'elysian_island',
        name = 'Elysian Island',
        zone = {
            points = {
                vector2(-400.0, -2800.0),
                vector2(-400.0, -2500.0),
                vector2(0.0, -2500.0),
                vector2(0.0, -2800.0)
            },
            minZ = -5.0,
            maxZ = 40.0
        },
        baseBonus = 1.15
    },
    -- Vinewood/Wealthy Areas
    {
        id = 'vinewood',
        name = 'Vinewood',
        zone = {
            points = {
                vector2(0.0, 0.0),
                vector2(0.0, 400.0),
                vector2(400.0, 400.0),
                vector2(400.0, 0.0)
            },
            minZ = 50.0,
            maxZ = 150.0
        },
        baseBonus = 1.35
    },
    {
        id = 'vinewood_hills',
        name = 'Vinewood Hills',
        zone = {
            points = {
                vector2(-200.0, 400.0),
                vector2(-200.0, 700.0),
                vector2(200.0, 700.0),
                vector2(200.0, 400.0)
            },
            minZ = 80.0,
            maxZ = 200.0
        },
        baseBonus = 1.4
    },
    {
        id = 'rockford_hills',
        name = 'Rockford Hills',
        zone = {
            points = {
                vector2(-900.0, 0.0),
                vector2(-900.0, 300.0),
                vector2(-600.0, 300.0),
                vector2(-600.0, 0.0)
            },
            minZ = 50.0,
            maxZ = 120.0
        },
        baseBonus = 1.3
    },
    -- Beach/Coastal Areas
    {
        id = 'del_perro',
        name = 'Del Perro Beach',
        zone = {
            points = {
                vector2(-1700.0, -1100.0),
                vector2(-1700.0, -800.0),
                vector2(-1400.0, -800.0),
                vector2(-1400.0, -1100.0)
            },
            minZ = 0.0,
            maxZ = 50.0
        },
        baseBonus = 1.2
    },
    {
        id = 'vespucci',
        name = 'Vespucci Beach',
        zone = {
            points = {
                vector2(-1500.0, -1300.0),
                vector2(-1500.0, -1100.0),
                vector2(-1200.0, -1100.0),
                vector2(-1200.0, -1300.0)
            },
            minZ = 0.0,
            maxZ = 40.0
        },
        baseBonus = 1.15
    },
    -- Sandy Shores / Desert
    {
        id = 'sandy_shores',
        name = 'Sandy Shores',
        zone = {
            points = {
                vector2(1700.0, 3600.0),
                vector2(1700.0, 3900.0),
                vector2(2100.0, 3900.0),
                vector2(2100.0, 3600.0)
            },
            minZ = 30.0,
            maxZ = 60.0
        },
        baseBonus = 1.1
    },
    {
        id = 'grapeseed',
        name = 'Grapeseed',
        zone = {
            points = {
                vector2(1600.0, 4700.0),
                vector2(1600.0, 5000.0),
                vector2(2000.0, 5000.0),
                vector2(2000.0, 4700.0)
            },
            minZ = 30.0,
            maxZ = 80.0
        },
        baseBonus = 1.0
    },
    -- Paleto Bay
    {
        id = 'paleto_bay',
        name = 'Paleto Bay',
        zone = {
            points = {
                vector2(-300.0, 6200.0),
                vector2(-300.0, 6500.0),
                vector2(100.0, 6500.0),
                vector2(100.0, 6200.0)
            },
            minZ = 0.0,
            maxZ = 50.0
        },
        baseBonus = 1.0
    },
    -- Mirror Park
    {
        id = 'mirror_park',
        name = 'Mirror Park',
        zone = {
            points = {
                vector2(900.0, -600.0),
                vector2(900.0, -400.0),
                vector2(1200.0, -400.0),
                vector2(1200.0, -600.0)
            },
            minZ = 30.0,
            maxZ = 80.0
        },
        baseBonus = 1.15
    },
    -- Downtown
    {
        id = 'downtown_vinewood',
        name = 'Downtown Vinewood',
        zone = {
            points = {
                vector2(-500.0, -300.0),
                vector2(-500.0, 0.0),
                vector2(-200.0, 0.0),
                vector2(-200.0, -300.0)
            },
            minZ = 30.0,
            maxZ = 100.0
        },
        baseBonus = 1.25
    },
    -- Pillbox Hill
    {
        id = 'pillbox_hill',
        name = 'Pillbox Hill',
        zone = {
            points = {
                vector2(0.0, -800.0),
                vector2(0.0, -600.0),
                vector2(300.0, -600.0),
                vector2(300.0, -800.0)
            },
            minZ = 25.0,
            maxZ = 100.0
        },
        baseBonus = 1.2
    }
}

-- NUI Settings
Config.NUI = {
    defaultTab = 'settings',
    refreshInterval = 30000, -- 30 seconds
    maxLogEntries = 100
}
