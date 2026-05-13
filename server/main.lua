local config = require 'config.server'

if config.command.enabled then
    lib.addCommand(config.command.name, {
        help = locale('command.help'),
        restricted = config.command.restricted
    }, function(source)
        TriggerClientEvent('telescopes:client:UseTelescope', source)
    end)
end