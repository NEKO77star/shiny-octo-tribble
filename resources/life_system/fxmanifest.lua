--[[
    Resource: life_system
    Purpose: Life & Roleplay System for FiveM QBCore server
    
    Responsibilities:
    - Property system (apartments, offices, hideouts, shops)
    - Insurance system (vehicle, health, property)
    - Phone UI with various apps
    - Legal jobs integration
    - Hobbies (fishing, gambling, racing)
    
    Database tables used:
    - properties
    - insurances
    
    Events:
    - server:life:* (server events)
    - client:life:* (client events)
    - qb_life:server:* (callbacks)
]]

fx_version 'cerulean'
game 'gta5'

author 'FiveM Development Team'
description 'Life & Roleplay System - Properties, insurance, phone, jobs and hobbies'
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
    'oxmysql'
}
