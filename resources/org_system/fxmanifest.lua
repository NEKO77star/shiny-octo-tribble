--[[
    Resource: org_system
    Purpose: Organization & Territory System for FiveM QBCore server
    
    Responsibilities:
    - Manage organizations (mafia, gangs, companies, shops)
    - Manage members, roles, salaries, and revenue share
    - Manage territories that give bonuses to criminal activities
    - Provide UI to configure contracts, salaries, and profit sharing
    
    Database tables used:
    - organizations
    - organization_members
    - org_assets
    - hidden_accounts
    - territories
    - territory_conflicts
    
    Events:
    - server:org:* (server events)
    - client:org:* (client events)
    - qb_org:server:* (callbacks)
]]

fx_version 'cerulean'
game 'gta5'

author 'FiveM Development Team'
description 'Organization & Territory System - Manages organizations, members, assets, and territories'
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
    'ox_inventory'
}
