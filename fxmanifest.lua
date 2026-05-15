fx_version 'cerulean'
game 'gta5'

author 'Mads'
description 'Telescopes'
version '1.4.2'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
}

client_script {
    'client/main.lua',
}

server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'locales/*.json',
    'config/client.lua',
    'config/server.lua',
}

dependencies {
    'ox_lib'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'