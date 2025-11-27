--[[
    Resource: economy_system
    File: config.lua
    Purpose: Configuration settings for the Criminal Economy System
    
    Contains:
    - Activity definitions and requirements
    - Market settings
    - Risk levels and cooldowns
    - Reward multipliers
]]

Config = {}

-- Activity Types
Config.ActivityTypes = {
    ['drug'] = {
        label = 'Drug Production/Distribution',
        icon = 'fa-cannabis',
        color = '#4caf50'
    },
    ['weapon'] = {
        label = 'Weapon Smuggling',
        icon = 'fa-gun',
        color = '#ff5722'
    },
    ['loan_shark'] = {
        label = 'Loan Sharking',
        icon = 'fa-hand-holding-dollar',
        color = '#ffc107'
    },
    ['fraud'] = {
        label = 'Online Fraud',
        icon = 'fa-credit-card',
        color = '#9c27b0'
    },
    ['laundry'] = {
        label = 'Money Laundering',
        icon = 'fa-money-bill-wave',
        color = '#2196f3'
    },
    ['human_traffic'] = {
        label = 'Protection Services',
        icon = 'fa-user-shield',
        color = '#795548'
    }
}

-- Predefined Activities
Config.Activities = {
    {
        id = 'drug_meth_cook',
        type = 'drug',
        name = 'Meth Cooking',
        description = 'Cook methamphetamine in a hidden lab',
        location = 'Grapeseed Lab',
        coords = vector3(2432.0, 4969.0, 46.0),
        requiredPlayers = 1,
        requiredEquipment = {'meth_ingredient', 'lab_equipment'},
        baseRewardMin = 5000,
        baseRewardMax = 15000,
        riskLevel = 7,
        cooldown = 1800, -- 30 minutes
        commodity = 'drug_meth',
        supplyAmount = 50
    },
    {
        id = 'drug_weed_harvest',
        type = 'drug',
        name = 'Weed Harvesting',
        description = 'Harvest cannabis plants',
        location = 'Marlowe Vineyard',
        coords = vector3(-1887.0, 2064.0, 141.0),
        requiredPlayers = 1,
        requiredEquipment = {'harvesting_tools'},
        baseRewardMin = 2000,
        baseRewardMax = 6000,
        riskLevel = 4,
        cooldown = 900, -- 15 minutes
        commodity = 'drug_weed',
        supplyAmount = 30
    },
    {
        id = 'weapon_smuggle',
        type = 'weapon',
        name = 'Weapon Smuggling',
        description = 'Smuggle weapons from the port',
        location = 'Port of LS',
        coords = vector3(130.0, -2530.0, 6.0),
        requiredPlayers = 2,
        requiredEquipment = {'lockpick'},
        baseRewardMin = 10000,
        baseRewardMax = 30000,
        riskLevel = 9,
        cooldown = 3600, -- 1 hour
        commodity = 'weapon_pistol',
        supplyAmount = 10
    },
    {
        id = 'weapon_modify',
        type = 'weapon',
        name = 'Weapon Modification',
        description = 'Modify weapons with illegal parts',
        location = 'Underground Workshop',
        coords = vector3(967.0, -1481.0, 31.0),
        requiredPlayers = 1,
        requiredEquipment = {'weapon_parts', 'toolkit'},
        baseRewardMin = 8000,
        baseRewardMax = 20000,
        riskLevel = 6,
        cooldown = 2700, -- 45 minutes
        commodity = 'weapon_parts',
        supplyAmount = 15
    },
    {
        id = 'loan_shark_collect',
        type = 'loan_shark',
        name = 'Debt Collection',
        description = 'Collect debts from borrowers',
        location = 'Various',
        coords = vector3(-40.0, -1748.0, 29.0),
        requiredPlayers = 1,
        requiredEquipment = {},
        baseRewardMin = 3000,
        baseRewardMax = 10000,
        riskLevel = 5,
        cooldown = 1200, -- 20 minutes
        commodity = 'dirty_money',
        supplyAmount = 0
    },
    {
        id = 'fraud_atm',
        type = 'fraud',
        name = 'ATM Skimming',
        description = 'Install and collect from ATM skimmers',
        location = 'Downtown',
        coords = vector3(147.0, -1035.0, 29.0),
        requiredPlayers = 1,
        requiredEquipment = {'atm_skimmer'},
        baseRewardMin = 4000,
        baseRewardMax = 12000,
        riskLevel = 6,
        cooldown = 1800, -- 30 minutes
        commodity = 'stolen_data',
        supplyAmount = 0
    },
    {
        id = 'fraud_credit',
        type = 'fraud',
        name = 'Credit Card Cloning',
        description = 'Clone credit cards from stolen data',
        location = 'Tech Workshop',
        coords = vector3(-1088.0, -248.0, 37.0),
        requiredPlayers = 1,
        requiredEquipment = {'card_reader', 'blank_cards'},
        baseRewardMin = 6000,
        baseRewardMax = 18000,
        riskLevel = 7,
        cooldown = 2400, -- 40 minutes
        commodity = 'cloned_cards',
        supplyAmount = 0
    },
    {
        id = 'laundry_business',
        type = 'laundry',
        name = 'Business Laundering',
        description = 'Launder money through front businesses',
        location = 'Downtown',
        coords = vector3(-46.0, -1757.0, 29.0),
        requiredPlayers = 1,
        requiredEquipment = {'dirty_money'},
        baseRewardMin = 0,
        baseRewardMax = 0,
        riskLevel = 3,
        cooldown = 3600, -- 1 hour
        commodity = 'clean_money',
        supplyAmount = 0,
        special = 'laundry' -- Special handling for laundering
    },
    {
        id = 'protection_racket',
        type = 'human_traffic',
        name = 'Protection Collection',
        description = 'Collect protection money from businesses',
        location = 'Various',
        coords = vector3(22.0, -1105.0, 29.0),
        requiredPlayers = 2,
        requiredEquipment = {},
        baseRewardMin = 5000,
        baseRewardMax = 15000,
        riskLevel = 6,
        cooldown = 2700, -- 45 minutes
        commodity = 'protection_money',
        supplyAmount = 0
    }
}

-- Market Settings
Config.Market = {
    basePrice = {
        ['drug_meth'] = 500,
        ['drug_weed'] = 200,
        ['drug_coke'] = 800,
        ['weapon_pistol'] = 5000,
        ['weapon_smg'] = 15000,
        ['weapon_rifle'] = 25000,
        ['weapon_parts'] = 1000,
        ['dirty_money'] = 1, -- per dollar
        ['stolen_data'] = 50,
        ['cloned_cards'] = 500
    },
    -- Price adjustment factors
    supplyMultiplier = 0.001, -- How much each unit of supply decreases price
    confiscationMultiplier = 0.002, -- How much each confiscated unit increases price
    maxPriceMultiplier = 3.0, -- Maximum price can be 3x base
    minPriceMultiplier = 0.3, -- Minimum price can be 0.3x base
    updateInterval = 300 -- Update market every 5 minutes (seconds)
}

-- Risk Settings
Config.Risk = {
    policeAlertChance = {
        [1] = 0.05, [2] = 0.10, [3] = 0.15, [4] = 0.20, [5] = 0.25,
        [6] = 0.35, [7] = 0.45, [8] = 0.55, [9] = 0.70, [10] = 0.85
    },
    policeAlertRadius = 500.0,
    policeBlipDuration = 60000 -- 1 minute
}

-- Organization Bonus
Config.OrgBonus = {
    territoryBonusEnabled = true,
    baseOrgBonus = 1.1, -- 10% bonus for being in an org
    maxTerritoryBonus = 1.5 -- Max 50% bonus from territory
}

-- Money Laundering Settings
Config.Laundering = {
    fee = 0.15, -- 15% laundering fee
    minAmount = 5000,
    maxAmount = 500000,
    riskPerLaunder = 5 -- Risk level increase per laundering
}

-- Cooldown Management
Config.Cooldowns = {
    global = 60, -- Global cooldown between any activity (seconds)
    perPlayer = true -- Cooldowns are per-player (vs per-activity)
}

-- NUI Settings
Config.NUI = {
    defaultTab = 'activities',
    refreshInterval = 30000
}
