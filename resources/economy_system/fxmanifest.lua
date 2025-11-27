--[[
    Resource: economy_system
    Purpose: Criminal Economy System for FiveM QBCore server
    
    Responsibilities:
    - Manage criminal activities (drug, weapon, fraud, etc.)
    - Implement dynamic market pricing
    - Handle rewards and distribution based on org membership
    - Track supply, demand, and police confiscations
    
    Database tables used:
    - criminal_activities
    - market_index
    
    Events:
    - server:economy:* (server events)
    - client:economy:* (client events)
    - qb_economy:server:* (callbacks)
]]

fx_version 'cerulean'
game 'gta5'

author 'FiveM Development Team'
description 'Criminal Economy System - Manages criminal activities and dynamic market'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/style.css',
    'nui/src/*.js'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_inventory',
    'org_system'
}
