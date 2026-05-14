local config = require 'config.server'

if config.command.enabled then
    lib.addCommand(config.command.name, {
        help = locale('command.help'),
        restricted = config.command.restricted
    }, function(source)
        if not exports.qbx_core:IsOptin(source) then TriggerClientEvent('ox_lib:notify', source, locale('command.not_optin'), 'error') return end
        TriggerClientEvent('telescopes:client:UseTelescope', source)
    end)
end