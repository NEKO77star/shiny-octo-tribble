--[[
    Resource: life_system
    File: config.lua
    Purpose: Configuration settings for the Life & Roleplay System
    
    Contains:
    - Property types and settings
    - Insurance types and rates
    - Phone app configurations
    - Legal job settings
    - Hobby configurations
]]

Config = {}

-- Property Types
Config.PropertyTypes = {
    ['apartment'] = {
        label = 'Apartment',
        icon = 'fa-building',
        canRent = true,
        canBuy = true,
        defaultRent = 500,
        defaultPrice = 50000
    },
    ['office'] = {
        label = 'Office',
        icon = 'fa-briefcase',
        canRent = true,
        canBuy = true,
        defaultRent = 1000,
        defaultPrice = 150000
    },
    ['gang_hideout'] = {
        label = 'Gang Hideout',
        icon = 'fa-skull',
        canRent = false,
        canBuy = true,
        defaultPrice = 250000,
        requiresOrg = true
    },
    ['shop'] = {
        label = 'Shop',
        icon = 'fa-store',
        canRent = true,
        canBuy = true,
        defaultRent = 2000,
        defaultPrice = 300000
    }
}

-- Predefined Properties
Config.Properties = {
    {
        id = 'apt_alta_1',
        name = 'Alta St Apartment #1',
        type = 'apartment',
        coords = vector3(-271.0, -938.0, 31.0),
        interior = 'high_end_apartment',
        rentPrice = 800,
        salePrice = 80000
    },
    {
        id = 'apt_eclipse_1',
        name = 'Eclipse Towers #1',
        type = 'apartment',
        coords = vector3(-773.0, 312.0, 85.0),
        interior = 'luxury_apartment',
        rentPrice = 1500,
        salePrice = 200000
    },
    {
        id = 'office_maze_bank',
        name = 'Maze Bank Office',
        type = 'office',
        coords = vector3(-75.0, -826.0, 243.0),
        interior = 'executive_office',
        rentPrice = 5000,
        salePrice = 1000000
    },
    {
        id = 'shop_convenience_1',
        name = 'Convenience Store - Vinewood',
        type = 'shop',
        coords = vector3(25.0, -1347.0, 29.0),
        interior = 'small_shop',
        rentPrice = 3000,
        salePrice = 500000
    }
}

-- Insurance Types
Config.InsuranceTypes = {
    ['vehicle'] = {
        label = 'Vehicle Insurance',
        icon = 'fa-car',
        basePremium = 500,
        baseCoverage = 50000,
        coverageMultiplier = 100, -- coverage = premium * multiplier
        validityDays = 30
    },
    ['health'] = {
        label = 'Health Insurance',
        icon = 'fa-heart',
        basePremium = 200,
        baseCoverage = 20000,
        coverageMultiplier = 100,
        validityDays = 30
    },
    ['property'] = {
        label = 'Property Insurance',
        icon = 'fa-home',
        basePremium = 1000,
        baseCoverage = 100000,
        coverageMultiplier = 100,
        validityDays = 30
    }
}

-- Phone Apps
Config.PhoneApps = {
    {
        id = 'messages',
        name = 'Messages',
        icon = 'fa-comments',
        enabled = true
    },
    {
        id = 'sns',
        name = 'SNS',
        icon = 'fa-share-nodes',
        enabled = true
    },
    {
        id = 'secure_chat',
        name = 'SecureChat',
        icon = 'fa-lock',
        enabled = true,
        requiresOrg = false
    },
    {
        id = 'bank',
        name = 'Bank',
        icon = 'fa-university',
        enabled = true
    },
    {
        id = 'jobs',
        name = 'Jobs',
        icon = 'fa-briefcase',
        enabled = true
    },
    {
        id = 'contacts',
        name = 'Contacts',
        icon = 'fa-address-book',
        enabled = true
    },
    {
        id = 'settings',
        name = 'Settings',
        icon = 'fa-cog',
        enabled = true
    }
}

-- Legal Jobs
Config.LegalJobs = {
    {
        id = 'taxi',
        name = 'Taxi Driver',
        description = 'Transport citizens around the city',
        requirements = {},
        basePayment = 100,
        bonusPerDistance = 5
    },
    {
        id = 'delivery',
        name = 'Delivery Driver',
        description = 'Deliver packages to various locations',
        requirements = {'driver_license'},
        basePayment = 150,
        bonusPerDelivery = 50
    },
    {
        id = 'mechanic',
        name = 'Mechanic',
        description = 'Repair and modify vehicles',
        requirements = {},
        basePayment = 200,
        bonusPerRepair = 100
    },
    {
        id = 'fishing',
        name = 'Fisherman',
        description = 'Catch and sell fish',
        requirements = {},
        basePayment = 0,
        sellLocation = vector3(-1841.0, -1199.0, 14.0)
    }
}

-- Fishing Configuration
Config.Fishing = {
    enabled = true,
    spots = {
        {
            coords = vector3(-1841.0, -1199.0, 14.0),
            name = 'Del Perro Pier'
        },
        {
            coords = vector3(1298.0, 4217.0, 33.0),
            name = 'Alamo Sea'
        }
    },
    fish = {
        {name = 'bass', label = 'Bass', price = 50, rarity = 0.4},
        {name = 'salmon', label = 'Salmon', price = 80, rarity = 0.3},
        {name = 'tuna', label = 'Tuna', price = 150, rarity = 0.15},
        {name = 'shark', label = 'Shark', price = 500, rarity = 0.05},
        {name = 'trash', label = 'Trash', price = 5, rarity = 0.1}
    }
}

-- Gambling Configuration
Config.Gambling = {
    enabled = true,
    casinoLocation = vector3(924.0, 47.0, 81.0),
    minBet = 100,
    maxBet = 100000,
    games = {
        {id = 'slots', name = 'Slot Machine', multiplier = 2.5, chance = 0.35},
        {id = 'blackjack', name = 'Blackjack', multiplier = 2.0, chance = 0.45},
        {id = 'roulette', name = 'Roulette', multiplier = 35.0, chance = 0.027}
    }
}

-- Racing Configuration
Config.Racing = {
    enabled = true,
    minPlayers = 2,
    maxBet = 50000,
    tracks = {
        {
            id = 'airport_loop',
            name = 'Airport Loop',
            checkpoints = {
                vector3(-1037.0, -2968.0, 13.0),
                vector3(-1336.0, -2535.0, 13.0),
                vector3(-1545.0, -2149.0, 13.0),
                vector3(-1037.0, -2968.0, 13.0)
            }
        }
    }
}

-- NUI Settings
Config.NUI = {
    phonePosition = 'right', -- left or right
    defaultApp = 'messages'
}
