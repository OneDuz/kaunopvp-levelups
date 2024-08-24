fx_version 'cerulean'
game 'gta5'

lua54 "yes"

author "onecodes"
version "1.0.5"
description 'level up system with leaderboard and admin panel lib.callback('one-codes:levels:AddXP', source, function() end, 500, false, "Del turfo")'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
    'config.lua'
}

client_scripts {
    'client.lua',
    'config.lua'
}

shared_script '@es_extended/imports.lua'
shared_script '@ox_lib/init.lua'
