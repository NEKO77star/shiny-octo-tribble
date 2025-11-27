--[[
    Resource: police_system
    Purpose: Police & Justice System for FiveM QBCore server
    
    Responsibilities:
    - Manage cases with suspects, witnesses, and victims
    - Evidence collection and management
    - Vehicle and person lookups
    - Prosecution and court system
    - Integration with economy_system for asset seizure
    
    Database tables used:
    - cases
    - case_suspects
    - evidence
    - vehicle_checks
    
    Events:
    - server:police:* (server events)
    - client:police:* (client events)
    - qb_police:server:* (callbacks)
]]

fx_version 'cerulean'
game 'gta5'

author 'FiveM Development Team'
description 'Police & Justice System - Manages cases, evidence, and court proceedings'
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
