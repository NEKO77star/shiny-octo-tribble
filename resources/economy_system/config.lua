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
    },
    -- New VCR GTA-style crime types
    ['robbery'] = {
        label = 'Robbery',
        icon = 'fa-mask',
        color = '#e91e63'
    },
    ['heist'] = {
        label = 'Heist',
        icon = 'fa-vault',
        color = '#673ab7'
    },
    ['burglary'] = {
        label = 'Burglary',
        icon = 'fa-house-crack',
        color = '#607d8b'
    },
    ['car_theft'] = {
        label = 'Car Theft',
        icon = 'fa-car-side',
        color = '#00bcd4'
    },
    ['kidnapping'] = {
        label = 'Kidnapping',
        icon = 'fa-user-lock',
        color = '#ff5252'
    },
    ['hacking'] = {
        label = 'Hacking',
        icon = 'fa-laptop-code',
        color = '#00e676'
    },
    ['smuggling'] = {
        label = 'Smuggling',
        icon = 'fa-truck-ramp-box',
        color = '#8d6e63'
    },
    ['chop_shop'] = {
        label = 'Chop Shop',
        icon = 'fa-screwdriver-wrench',
        color = '#ffab00'
    },
    ['street_racing'] = {
        label = 'Illegal Street Racing',
        icon = 'fa-flag-checkered',
        color = '#d500f9'
    },
    ['hitman'] = {
        label = 'Contract Killing',
        icon = 'fa-crosshairs',
        color = '#212121'
    }
}

-- Predefined Activities
Config.Activities = {
    -- Drug Activities
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
        id = 'drug_coke_process',
        type = 'drug',
        name = 'Cocaine Processing',
        description = 'Process raw cocaine in a hidden warehouse',
        location = 'Industrial Warehouse',
        coords = vector3(1087.0, -2015.0, 31.0),
        requiredPlayers = 2,
        requiredEquipment = {'coca_leaves', 'processing_chemicals'},
        baseRewardMin = 8000,
        baseRewardMax = 25000,
        riskLevel = 8,
        cooldown = 2400, -- 40 minutes
        commodity = 'drug_coke',
        supplyAmount = 40
    },
    {
        id = 'drug_heroin_cut',
        type = 'drug',
        name = 'Heroin Cutting',
        description = 'Cut and package heroin for street distribution',
        location = 'Abandoned Motel',
        coords = vector3(1511.0, 3685.0, 34.0),
        requiredPlayers = 1,
        requiredEquipment = {'raw_heroin', 'cutting_agent'},
        baseRewardMin = 6000,
        baseRewardMax = 18000,
        riskLevel = 7,
        cooldown = 1800,
        commodity = 'drug_heroin',
        supplyAmount = 35
    },
    -- Weapon Activities
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
        id = 'weapon_manufacture',
        type = 'weapon',
        name = 'Ghost Gun Manufacturing',
        description = 'Manufacture untraceable firearms',
        location = 'Hidden Bunker',
        coords = vector3(2493.0, 3764.0, 43.0),
        requiredPlayers = 2,
        requiredEquipment = {'gun_molds', 'metal_sheets', 'machinery'},
        baseRewardMin = 20000,
        baseRewardMax = 50000,
        riskLevel = 10,
        cooldown = 5400, -- 90 minutes
        commodity = 'weapon_ghost',
        supplyAmount = 5
    },
    -- Robbery Activities
    {
        id = 'robbery_convenience',
        type = 'robbery',
        name = 'Convenience Store Robbery',
        description = 'Rob a 24/7 convenience store',
        location = 'Various 24/7 Stores',
        coords = vector3(25.0, -1347.0, 29.0),
        requiredPlayers = 1,
        requiredEquipment = {'weapon'},
        baseRewardMin = 1000,
        baseRewardMax = 5000,
        riskLevel = 4,
        cooldown = 600, -- 10 minutes
        commodity = 'dirty_money',
        supplyAmount = 0
    },
    {
        id = 'robbery_liquor',
        type = 'robbery',
        name = 'Liquor Store Robbery',
        description = 'Rob a liquor store',
        location = 'Liquor Store',
        coords = vector3(-1222.0, -906.0, 12.0),
        requiredPlayers = 1,
        requiredEquipment = {'weapon'},
        baseRewardMin = 2000,
        baseRewardMax = 7000,
        riskLevel = 5,
        cooldown = 900,
        commodity = 'dirty_money',
        supplyAmount = 0
    },
    {
        id = 'robbery_jewelry',
        type = 'robbery',
        name = 'Jewelry Store Heist',
        description = 'Rob Vangelico Fine Jewelry',
        location = 'Vangelico Jewelry',
        coords = vector3(-630.0, -236.0, 38.0),
        requiredPlayers = 3,
        requiredEquipment = {'thermal_charge', 'weapon', 'bag'},
        baseRewardMin = 30000,
        baseRewardMax = 80000,
        riskLevel = 8,
        cooldown = 3600,
        commodity = 'jewelry',
        supplyAmount = 0
    },
    {
        id = 'robbery_fleeca',
        type = 'robbery',
        name = 'Fleeca Bank Robbery',
        description = 'Rob a local Fleeca bank branch',
        location = 'Fleeca Bank',
        coords = vector3(149.0, -1040.0, 29.0),
        requiredPlayers = 2,
        requiredEquipment = {'thermite', 'laptop', 'weapon'},
        baseRewardMin = 20000,
        baseRewardMax = 60000,
        riskLevel = 7,
        cooldown = 2700,
        commodity = 'marked_bills',
        supplyAmount = 0
    },
    -- Heist Activities
    {
        id = 'heist_pacific',
        type = 'heist',
        name = 'Pacific Standard Heist',
        description = 'Rob the Pacific Standard Bank',
        location = 'Pacific Standard Bank',
        coords = vector3(235.0, 216.0, 106.0),
        requiredPlayers = 4,
        requiredEquipment = {'heavy_drill', 'thermite', 'thermal_charge', 'weapon', 'getaway_vehicle'},
        baseRewardMin = 100000,
        baseRewardMax = 300000,
        riskLevel = 10,
        cooldown = 7200, -- 2 hours
        commodity = 'marked_bills',
        supplyAmount = 0
    },
    {
        id = 'heist_union',
        type = 'heist',
        name = 'Union Depository',
        description = 'The ultimate heist - Union Depository',
        location = 'Union Depository',
        coords = vector3(2.0, -667.0, 16.0),
        requiredPlayers = 6,
        requiredEquipment = {'emp_device', 'heavy_drill', 'thermite', 'rappelling_gear', 'weapon'},
        baseRewardMin = 500000,
        baseRewardMax = 1500000,
        riskLevel = 10,
        cooldown = 14400, -- 4 hours
        commodity = 'gold_bars',
        supplyAmount = 0
    },
    {
        id = 'heist_casino',
        type = 'heist',
        name = 'Diamond Casino Heist',
        description = 'Infiltrate and rob the Diamond Casino vault',
        location = 'Diamond Casino',
        coords = vector3(924.0, 47.0, 81.0),
        requiredPlayers = 4,
        requiredEquipment = {'hacking_device', 'emp_device', 'drill', 'weapon'},
        baseRewardMin = 200000,
        baseRewardMax = 600000,
        riskLevel = 10,
        cooldown = 10800, -- 3 hours
        commodity = 'casino_chips',
        supplyAmount = 0
    },
    -- Burglary Activities
    {
        id = 'burglary_house',
        type = 'burglary',
        name = 'House Burglary',
        description = 'Break into residential homes and steal valuables',
        location = 'Residential Areas',
        coords = vector3(-174.0, 502.0, 137.0),
        requiredPlayers = 1,
        requiredEquipment = {'lockpick', 'bag'},
        baseRewardMin = 3000,
        baseRewardMax = 15000,
        riskLevel = 5,
        cooldown = 1200,
        commodity = 'stolen_goods',
        supplyAmount = 0
    },
    {
        id = 'burglary_mansion',
        type = 'burglary',
        name = 'Mansion Burglary',
        description = 'Break into Vinewood mansions for high-end items',
        location = 'Vinewood Hills',
        coords = vector3(-1523.0, 142.0, 55.0),
        requiredPlayers = 2,
        requiredEquipment = {'advanced_lockpick', 'signal_jammer', 'bag'},
        baseRewardMin = 15000,
        baseRewardMax = 50000,
        riskLevel = 7,
        cooldown = 2400,
        commodity = 'luxury_goods',
        supplyAmount = 0
    },
    {
        id = 'burglary_warehouse',
        type = 'burglary',
        name = 'Warehouse Burglary',
        description = 'Steal goods from industrial warehouses',
        location = 'Industrial Area',
        coords = vector3(1059.0, -2007.0, 31.0),
        requiredPlayers = 2,
        requiredEquipment = {'bolt_cutters', 'forklift_key'},
        baseRewardMin = 10000,
        baseRewardMax = 30000,
        riskLevel = 6,
        cooldown = 1800,
        commodity = 'warehouse_goods',
        supplyAmount = 0
    },
    -- Car Theft Activities
    {
        id = 'car_theft_street',
        type = 'car_theft',
        name = 'Street Car Theft',
        description = 'Steal cars from the street for the chop shop',
        location = 'Various Locations',
        coords = vector3(-47.0, -1083.0, 26.0),
        requiredPlayers = 1,
        requiredEquipment = {'slim_jim'},
        baseRewardMin = 2000,
        baseRewardMax = 10000,
        riskLevel = 4,
        cooldown = 600,
        commodity = 'car_parts',
        supplyAmount = 0
    },
    {
        id = 'car_theft_exotic',
        type = 'car_theft',
        name = 'Exotic Car Theft',
        description = 'Steal high-end exotic vehicles to order',
        location = 'Various Locations',
        coords = vector3(-58.0, -1112.0, 26.0),
        requiredPlayers = 2,
        requiredEquipment = {'advanced_slim_jim', 'signal_jammer'},
        baseRewardMin = 20000,
        baseRewardMax = 80000,
        riskLevel = 8,
        cooldown = 3600,
        commodity = 'exotic_car',
        supplyAmount = 0
    },
    {
        id = 'car_theft_boosting',
        type = 'car_theft',
        name = 'Contract Boosting',
        description = 'Complete vehicle boosting contracts from the underground',
        location = 'Underground Market',
        coords = vector3(969.0, -1822.0, 31.0),
        requiredPlayers = 1,
        requiredEquipment = {'var_device'},
        baseRewardMin = 5000,
        baseRewardMax = 25000,
        riskLevel = 6,
        cooldown = 1200,
        commodity = 'vehicle_contract',
        supplyAmount = 0
    },
    -- Chop Shop Activities
    {
        id = 'chop_shop_dismantle',
        type = 'chop_shop',
        name = 'Vehicle Dismantling',
        description = 'Dismantle stolen vehicles for parts',
        location = 'Chop Shop',
        coords = vector3(487.0, -1314.0, 29.0),
        requiredPlayers = 1,
        requiredEquipment = {'stolen_vehicle'},
        baseRewardMin = 5000,
        baseRewardMax = 15000,
        riskLevel = 5,
        cooldown = 1200,
        commodity = 'car_parts',
        supplyAmount = 20
    },
    {
        id = 'chop_shop_vin',
        type = 'chop_shop',
        name = 'VIN Scratching',
        description = 'Change VIN numbers to make stolen cars untraceable',
        location = 'Underground Garage',
        coords = vector3(-600.0, -1619.0, 26.0),
        requiredPlayers = 1,
        requiredEquipment = {'vin_kit'},
        baseRewardMin = 3000,
        baseRewardMax = 8000,
        riskLevel = 4,
        cooldown = 900,
        commodity = 'clean_title',
        supplyAmount = 0
    },
    -- Kidnapping Activities
    {
        id = 'kidnapping_ransom',
        type = 'kidnapping',
        name = 'Ransom Kidnapping',
        description = 'Kidnap high-profile targets for ransom',
        location = 'Various',
        coords = vector3(-1544.0, -567.0, 25.0),
        requiredPlayers = 3,
        requiredEquipment = {'zip_ties', 'blindfold', 'vehicle'},
        baseRewardMin = 30000,
        baseRewardMax = 100000,
        riskLevel = 9,
        cooldown = 5400,
        commodity = 'ransom_money',
        supplyAmount = 0
    },
    -- Hacking Activities
    {
        id = 'hacking_crypto',
        type = 'hacking',
        name = 'Crypto Mining Hack',
        description = 'Hack into crypto mining operations',
        location = 'Server Farm',
        coords = vector3(2158.0, 2920.0, -62.0),
        requiredPlayers = 1,
        requiredEquipment = {'hacking_laptop'},
        baseRewardMin = 10000,
        baseRewardMax = 40000,
        riskLevel = 6,
        cooldown = 2400,
        commodity = 'crypto',
        supplyAmount = 0
    },
    {
        id = 'hacking_identity',
        type = 'hacking',
        name = 'Identity Theft',
        description = 'Steal and sell personal identities',
        location = 'Various',
        coords = vector3(-1088.0, -248.0, 37.0),
        requiredPlayers = 1,
        requiredEquipment = {'hacking_laptop', 'stolen_data'},
        baseRewardMin = 8000,
        baseRewardMax = 25000,
        riskLevel = 7,
        cooldown = 1800,
        commodity = 'fake_id',
        supplyAmount = 0
    },
    -- Smuggling Activities
    {
        id = 'smuggling_boat',
        type = 'smuggling',
        name = 'Boat Smuggling',
        description = 'Smuggle goods via boat from international waters',
        location = 'Vespucci Beach',
        coords = vector3(-1610.0, -1010.0, 3.0),
        requiredPlayers = 2,
        requiredEquipment = {'boat'},
        baseRewardMin = 15000,
        baseRewardMax = 45000,
        riskLevel = 7,
        cooldown = 3600,
        commodity = 'smuggled_goods',
        supplyAmount = 0
    },
    {
        id = 'smuggling_plane',
        type = 'smuggling',
        name = 'Air Smuggling',
        description = 'Fly contraband using private aircraft',
        location = 'Sandy Shores Airfield',
        coords = vector3(1737.0, 3285.0, 41.0),
        requiredPlayers = 2,
        requiredEquipment = {'plane', 'pilot_license'},
        baseRewardMin = 30000,
        baseRewardMax = 90000,
        riskLevel = 9,
        cooldown = 5400,
        commodity = 'contraband',
        supplyAmount = 0
    },
    -- Street Racing Activities
    {
        id = 'street_racing_circuit',
        type = 'street_racing',
        name = 'Underground Circuit Race',
        description = 'Compete in illegal street races for cash',
        location = 'LS Underground',
        coords = vector3(-51.0, -1685.0, 29.0),
        requiredPlayers = 4,
        requiredEquipment = {'race_vehicle'},
        baseRewardMin = 10000,
        baseRewardMax = 50000,
        riskLevel = 5,
        cooldown = 1800,
        commodity = 'race_winnings',
        supplyAmount = 0
    },
    {
        id = 'street_racing_pink_slip',
        type = 'street_racing',
        name = 'Pink Slip Race',
        description = 'Race for vehicle titles - winner takes all',
        location = 'Various',
        coords = vector3(250.0, -337.0, 44.0),
        requiredPlayers = 2,
        requiredEquipment = {'valuable_vehicle'},
        baseRewardMin = 0,
        baseRewardMax = 0, -- Reward is opponent's vehicle
        riskLevel = 8,
        cooldown = 3600,
        commodity = 'vehicle_title',
        supplyAmount = 0,
        special = 'pink_slip'
    },
    -- Hitman Activities
    {
        id = 'hitman_contract',
        type = 'hitman',
        name = 'Contract Hit',
        description = 'Eliminate a target for payment',
        location = 'Anonymous',
        coords = vector3(100.0, -1942.0, 20.0),
        requiredPlayers = 1,
        requiredEquipment = {'untraceable_weapon'},
        baseRewardMin = 25000,
        baseRewardMax = 100000,
        riskLevel = 10,
        cooldown = 7200,
        commodity = 'blood_money',
        supplyAmount = 0
    },
    -- Original Activities
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
        -- Drugs
        ['drug_meth'] = 500,
        ['drug_weed'] = 200,
        ['drug_coke'] = 800,
        ['drug_heroin'] = 700,
        -- Weapons
        ['weapon_pistol'] = 5000,
        ['weapon_smg'] = 15000,
        ['weapon_rifle'] = 25000,
        ['weapon_parts'] = 1000,
        ['weapon_ghost'] = 35000,
        -- Stolen Goods
        ['dirty_money'] = 1, -- per dollar
        ['stolen_data'] = 50,
        ['cloned_cards'] = 500,
        ['jewelry'] = 2000,
        ['marked_bills'] = 0.5, -- per dollar (needs laundering)
        ['gold_bars'] = 50000,
        ['casino_chips'] = 0.8, -- per dollar
        ['stolen_goods'] = 100,
        ['luxury_goods'] = 500,
        ['warehouse_goods'] = 200,
        -- Car Theft
        ['car_parts'] = 300,
        ['exotic_car'] = 40000,
        ['vehicle_contract'] = 5000,
        ['clean_title'] = 2000,
        -- Other
        ['ransom_money'] = 1,
        ['crypto'] = 1000,
        ['fake_id'] = 1500,
        ['smuggled_goods'] = 400,
        ['contraband'] = 800,
        ['race_winnings'] = 1,
        ['vehicle_title'] = 10000,
        ['blood_money'] = 1
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
