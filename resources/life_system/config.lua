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
    },
    -- New VCR GTA-style property types
    ['warehouse'] = {
        label = 'Warehouse',
        icon = 'fa-warehouse',
        canRent = true,
        canBuy = true,
        defaultRent = 3000,
        defaultPrice = 500000
    },
    ['nightclub'] = {
        label = 'Nightclub',
        icon = 'fa-martini-glass',
        canRent = false,
        canBuy = true,
        defaultPrice = 1500000,
        canLaunder = true
    },
    ['bar'] = {
        label = 'Bar',
        icon = 'fa-beer-mug-empty',
        canRent = true,
        canBuy = true,
        defaultRent = 2500,
        defaultPrice = 400000
    },
    ['restaurant'] = {
        label = 'Restaurant',
        icon = 'fa-utensils',
        canRent = true,
        canBuy = true,
        defaultRent = 3500,
        defaultPrice = 600000
    },
    ['car_dealership'] = {
        label = 'Car Dealership',
        icon = 'fa-car',
        canRent = false,
        canBuy = true,
        defaultPrice = 2000000
    },
    ['garage'] = {
        label = 'Garage',
        icon = 'fa-warehouse',
        canRent = true,
        canBuy = true,
        defaultRent = 1500,
        defaultPrice = 200000
    },
    ['motel'] = {
        label = 'Motel',
        icon = 'fa-bed',
        canRent = true,
        canBuy = true,
        defaultRent = 800,
        defaultPrice = 350000
    },
    ['penthouse'] = {
        label = 'Penthouse',
        icon = 'fa-city',
        canRent = false,
        canBuy = true,
        defaultPrice = 3000000
    },
    ['mansion'] = {
        label = 'Mansion',
        icon = 'fa-house-chimney',
        canRent = false,
        canBuy = true,
        defaultPrice = 5000000
    },
    ['bunker'] = {
        label = 'Underground Bunker',
        icon = 'fa-vault',
        canRent = false,
        canBuy = true,
        defaultPrice = 2500000,
        requiresOrg = true
    },
    ['mc_clubhouse'] = {
        label = 'MC Clubhouse',
        icon = 'fa-motorcycle',
        canRent = false,
        canBuy = true,
        defaultPrice = 800000,
        requiresOrg = true
    },
    ['strip_club'] = {
        label = 'Strip Club',
        icon = 'fa-star',
        canRent = false,
        canBuy = true,
        defaultPrice = 1200000,
        canLaunder = true
    },
    ['casino'] = {
        label = 'Casino',
        icon = 'fa-dice',
        canRent = false,
        canBuy = true,
        defaultPrice = 10000000
    },
    ['factory'] = {
        label = 'Factory',
        icon = 'fa-industry',
        canRent = true,
        canBuy = true,
        defaultRent = 5000,
        defaultPrice = 1000000
    },
    ['farm'] = {
        label = 'Farm',
        icon = 'fa-tractor',
        canRent = false,
        canBuy = true,
        defaultPrice = 750000
    },
    ['hangar'] = {
        label = 'Aircraft Hangar',
        icon = 'fa-plane',
        canRent = false,
        canBuy = true,
        defaultPrice = 1500000
    },
    ['dock'] = {
        label = 'Private Dock',
        icon = 'fa-anchor',
        canRent = false,
        canBuy = true,
        defaultPrice = 800000
    }
}

-- Predefined Properties
Config.Properties = {
    -- Apartments
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
        id = 'apt_integrity_way',
        name = 'Integrity Way Apartment',
        type = 'apartment',
        coords = vector3(-47.0, -585.0, 37.0),
        interior = 'mid_range_apartment',
        rentPrice = 600,
        salePrice = 60000
    },
    {
        id = 'apt_del_perro',
        name = 'Del Perro Heights',
        type = 'apartment',
        coords = vector3(-1447.0, -538.0, 34.0),
        interior = 'high_end_apartment',
        rentPrice = 1200,
        salePrice = 150000
    },
    -- Penthouses
    {
        id = 'penthouse_casino',
        name = 'Diamond Casino Penthouse',
        type = 'penthouse',
        coords = vector3(976.0, 70.0, 116.0),
        interior = 'casino_penthouse',
        rentPrice = 0,
        salePrice = 5000000
    },
    {
        id = 'penthouse_eclipse',
        name = 'Eclipse Towers Penthouse',
        type = 'penthouse',
        coords = vector3(-773.0, 323.0, 211.0),
        interior = 'luxury_penthouse',
        rentPrice = 0,
        salePrice = 4000000
    },
    -- Mansions
    {
        id = 'mansion_richman',
        name = 'Richman Mansion',
        type = 'mansion',
        coords = vector3(-1523.0, 142.0, 55.0),
        interior = 'richman_mansion',
        rentPrice = 0,
        salePrice = 8000000
    },
    {
        id = 'mansion_vinewood',
        name = 'Vinewood Hills Estate',
        type = 'mansion',
        coords = vector3(-174.0, 502.0, 137.0),
        interior = 'vinewood_mansion',
        rentPrice = 0,
        salePrice = 6000000
    },
    {
        id = 'mansion_rockford',
        name = 'Rockford Hills Mansion',
        type = 'mansion',
        coords = vector3(-852.0, 160.0, 67.0),
        interior = 'rockford_mansion',
        rentPrice = 0,
        salePrice = 7500000
    },
    -- Offices
    {
        id = 'office_maze_bank',
        name = 'Maze Bank Tower Office',
        type = 'office',
        coords = vector3(-75.0, -826.0, 243.0),
        interior = 'executive_office',
        rentPrice = 5000,
        salePrice = 1000000
    },
    {
        id = 'office_arcadius',
        name = 'Arcadius Business Center',
        type = 'office',
        coords = vector3(-141.0, -621.0, 168.0),
        interior = 'executive_office_2',
        rentPrice = 4000,
        salePrice = 800000
    },
    {
        id = 'office_lombank',
        name = 'Lombank West Office',
        type = 'office',
        coords = vector3(-1581.0, -558.0, 108.0),
        interior = 'modern_office',
        rentPrice = 3500,
        salePrice = 700000
    },
    -- Shops
    {
        id = 'shop_convenience_1',
        name = 'Convenience Store - Vinewood',
        type = 'shop',
        coords = vector3(25.0, -1347.0, 29.0),
        interior = 'small_shop',
        rentPrice = 3000,
        salePrice = 500000
    },
    {
        id = 'shop_247_downtown',
        name = '24/7 - Downtown',
        type = 'shop',
        coords = vector3(373.0, 325.0, 103.0),
        interior = 'convenience_store',
        rentPrice = 2500,
        salePrice = 400000
    },
    {
        id = 'shop_ltds',
        name = 'LTD Gasoline',
        type = 'shop',
        coords = vector3(-707.0, -913.0, 19.0),
        interior = 'gas_station_shop',
        rentPrice = 2000,
        salePrice = 350000
    },
    -- Warehouses
    {
        id = 'warehouse_la_mesa',
        name = 'La Mesa Warehouse',
        type = 'warehouse',
        coords = vector3(1087.0, -2015.0, 31.0),
        interior = 'large_warehouse',
        rentPrice = 4000,
        salePrice = 600000
    },
    {
        id = 'warehouse_elysian',
        name = 'Elysian Island Warehouse',
        type = 'warehouse',
        coords = vector3(-147.0, -2728.0, 6.0),
        interior = 'medium_warehouse',
        rentPrice = 5000,
        salePrice = 750000
    },
    {
        id = 'warehouse_cypress',
        name = 'Cypress Flats Warehouse',
        type = 'warehouse',
        coords = vector3(738.0, -1856.0, 29.0),
        interior = 'industrial_warehouse',
        rentPrice = 3500,
        salePrice = 550000
    },
    -- Nightclubs
    {
        id = 'nightclub_downtown',
        name = 'Downtown Nightclub',
        type = 'nightclub',
        coords = vector3(-1604.0, -3012.0, -79.0),
        interior = 'downtown_nightclub',
        rentPrice = 0,
        salePrice = 1750000
    },
    {
        id = 'nightclub_del_perro',
        name = 'Del Perro Nightclub',
        type = 'nightclub',
        coords = vector3(-1373.0, -625.0, 30.0),
        interior = 'beach_nightclub',
        rentPrice = 0,
        salePrice = 1500000
    },
    {
        id = 'nightclub_vinewood',
        name = 'Vinewood Nightclub',
        type = 'nightclub',
        coords = vector3(176.0, -1170.0, 29.0),
        interior = 'vinewood_nightclub',
        rentPrice = 0,
        salePrice = 2000000
    },
    -- Bars
    {
        id = 'bar_yellow_jack',
        name = 'Yellow Jack Inn',
        type = 'bar',
        coords = vector3(1984.0, 3054.0, 47.0),
        interior = 'country_bar',
        rentPrice = 1500,
        salePrice = 300000
    },
    {
        id = 'bar_tequila',
        name = 'Tequi-la-la',
        type = 'bar',
        coords = vector3(-557.0, 286.0, 82.0),
        interior = 'rock_bar',
        rentPrice = 2000,
        salePrice = 450000
    },
    {
        id = 'bar_bahama',
        name = 'Bahama Mamas West',
        type = 'bar',
        coords = vector3(-1388.0, -587.0, 30.0),
        interior = 'beach_bar',
        rentPrice = 2500,
        salePrice = 500000
    },
    -- Restaurants
    {
        id = 'restaurant_burgershot',
        name = 'Burger Shot - Downtown',
        type = 'restaurant',
        coords = vector3(-1196.0, -892.0, 14.0),
        interior = 'fast_food',
        rentPrice = 3000,
        salePrice = 550000
    },
    {
        id = 'restaurant_cluckin',
        name = "Cluckin' Bell",
        type = 'restaurant',
        coords = vector3(-145.0, -255.0, 44.0),
        interior = 'fast_food_2',
        rentPrice = 2800,
        salePrice = 500000
    },
    {
        id = 'restaurant_bean',
        name = 'Bean Machine Cafe',
        type = 'restaurant',
        coords = vector3(-634.0, 237.0, 82.0),
        interior = 'cafe',
        rentPrice = 2000,
        salePrice = 350000
    },
    {
        id = 'restaurant_sushi',
        name = 'Little Tokyo Sushi',
        type = 'restaurant',
        coords = vector3(-682.0, -859.0, 23.0),
        interior = 'japanese_restaurant',
        rentPrice = 4000,
        salePrice = 700000
    },
    -- Car Dealerships
    {
        id = 'dealership_premium',
        name = 'Premium Deluxe Motorsport',
        type = 'car_dealership',
        coords = vector3(-56.0, -1097.0, 26.0),
        interior = 'luxury_dealership',
        rentPrice = 0,
        salePrice = 2500000
    },
    {
        id = 'dealership_simeon',
        name = "Simeon's Dealership",
        type = 'car_dealership',
        coords = vector3(-34.0, -1101.0, 26.0),
        interior = 'standard_dealership',
        rentPrice = 0,
        salePrice = 1800000
    },
    -- Garages
    {
        id = 'garage_pillbox',
        name = 'Pillbox Hill Garage',
        type = 'garage',
        coords = vector3(228.0, -788.0, 30.0),
        interior = '10_car_garage',
        rentPrice = 1500,
        salePrice = 250000
    },
    {
        id = 'garage_eclipse',
        name = 'Eclipse Blvd Garage',
        type = 'garage',
        coords = vector3(-774.0, 296.0, 85.0),
        interior = '6_car_garage',
        rentPrice = 1000,
        salePrice = 150000
    },
    -- Motels
    {
        id = 'motel_route68',
        name = 'Route 68 Motel',
        type = 'motel',
        coords = vector3(1136.0, 2663.0, 38.0),
        interior = 'motel_room',
        rentPrice = 300,
        salePrice = 200000
    },
    {
        id = 'motel_sandy',
        name = 'Sandy Shores Motel',
        type = 'motel',
        coords = vector3(1511.0, 3685.0, 34.0),
        interior = 'motel_room_2',
        rentPrice = 250,
        salePrice = 180000
    },
    -- Gang Hideouts
    {
        id = 'hideout_grove',
        name = 'Grove Street Hideout',
        type = 'gang_hideout',
        coords = vector3(93.0, -1969.0, 21.0),
        interior = 'gang_hideout_1',
        rentPrice = 0,
        salePrice = 350000
    },
    {
        id = 'hideout_ballas',
        name = 'Davis Avenue Hideout',
        type = 'gang_hideout',
        coords = vector3(110.0, -1963.0, 21.0),
        interior = 'gang_hideout_2',
        rentPrice = 0,
        salePrice = 300000
    },
    {
        id = 'hideout_vagos',
        name = 'Rancho Hideout',
        type = 'gang_hideout',
        coords = vector3(319.0, -2012.0, 23.0),
        interior = 'gang_hideout_3',
        rentPrice = 0,
        salePrice = 280000
    },
    -- Bunkers
    {
        id = 'bunker_chumash',
        name = 'Chumash Bunker',
        type = 'bunker',
        coords = vector3(-3058.0, 3327.0, 12.0),
        interior = 'underground_bunker',
        rentPrice = 0,
        salePrice = 2750000
    },
    {
        id = 'bunker_farmhouse',
        name = 'Farmhouse Bunker',
        type = 'bunker',
        coords = vector3(2493.0, 3764.0, 43.0),
        interior = 'large_bunker',
        rentPrice = 0,
        salePrice = 3000000
    },
    -- MC Clubhouses
    {
        id = 'mc_sandy',
        name = 'Sandy Shores MC Clubhouse',
        type = 'mc_clubhouse',
        coords = vector3(1939.0, 3817.0, 32.0),
        interior = 'mc_clubhouse_1',
        rentPrice = 0,
        salePrice = 900000
    },
    {
        id = 'mc_grapeseed',
        name = 'Grapeseed MC Clubhouse',
        type = 'mc_clubhouse',
        coords = vector3(1759.0, 4813.0, 42.0),
        interior = 'mc_clubhouse_2',
        rentPrice = 0,
        salePrice = 850000
    },
    -- Strip Clubs
    {
        id = 'strip_vanilla',
        name = 'Vanilla Unicorn',
        type = 'strip_club',
        coords = vector3(127.0, -1298.0, 29.0),
        interior = 'vanilla_unicorn',
        rentPrice = 0,
        salePrice = 1500000
    },
    -- Casino
    {
        id = 'casino_diamond',
        name = 'Diamond Casino & Resort',
        type = 'casino',
        coords = vector3(924.0, 47.0, 81.0),
        interior = 'diamond_casino',
        rentPrice = 0,
        salePrice = 15000000
    },
    -- Factories
    {
        id = 'factory_textile',
        name = 'Textile City Factory',
        type = 'factory',
        coords = vector3(717.0, -962.0, 25.0),
        interior = 'industrial_factory',
        rentPrice = 6000,
        salePrice = 1200000
    },
    {
        id = 'factory_rancho',
        name = 'Rancho Industrial Factory',
        type = 'factory',
        coords = vector3(537.0, -1930.0, 25.0),
        interior = 'large_factory',
        rentPrice = 8000,
        salePrice = 1500000
    },
    -- Farms
    {
        id = 'farm_grapeseed',
        name = 'Grapeseed Farm',
        type = 'farm',
        coords = vector3(2012.0, 4987.0, 42.0),
        interior = 'large_farm',
        rentPrice = 0,
        salePrice = 900000
    },
    {
        id = 'farm_madrazo',
        name = 'Madrazo Ranch',
        type = 'farm',
        coords = vector3(1391.0, 1158.0, 114.0),
        interior = 'ranch_house',
        rentPrice = 0,
        salePrice = 1200000
    },
    -- Hangars
    {
        id = 'hangar_lsia',
        name = 'LSIA Hangar',
        type = 'hangar',
        coords = vector3(-1218.0, -2994.0, 14.0),
        interior = 'aircraft_hangar',
        rentPrice = 0,
        salePrice = 1800000
    },
    {
        id = 'hangar_sandy',
        name = 'Sandy Shores Hangar',
        type = 'hangar',
        coords = vector3(1737.0, 3285.0, 41.0),
        interior = 'small_hangar',
        rentPrice = 0,
        salePrice = 900000
    },
    -- Docks
    {
        id = 'dock_vespucci',
        name = 'Vespucci Beach Dock',
        type = 'dock',
        coords = vector3(-1610.0, -1010.0, 3.0),
        interior = 'private_dock',
        rentPrice = 0,
        salePrice = 750000
    },
    {
        id = 'dock_paleto',
        name = 'Paleto Bay Dock',
        type = 'dock',
        coords = vector3(-1630.0, 5265.0, 0.0),
        interior = 'private_dock_2',
        rentPrice = 0,
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
