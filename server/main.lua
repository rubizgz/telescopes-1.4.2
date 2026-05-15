local config = require 'config.server'
local telescopes = {}

if config.command.enabled then
    lib.addCommand(config.command.name, {
        help = locale('command.telescope_help'),
        restricted = config.command.restricted
    }, function(source)
        if not exports.qbx_core:IsOptin(source) then TriggerClientEvent('ox_lib:notify', source, locale('command.admin_not_optin'), 'error') return end
        TriggerClientEvent('telescopes:client:InteractTelescope', source)
    end)
end

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM `telescopes`', {}, function(result)
        for _, v in pairs(result) do
            telescopes[v.id] = { coords = json.decode(v.coords), telescope = v.telescope }
        end
    end)
end)

local function updateTelescopes()
    for _, v in pairs(GetPlayers()) do
        lib.callback.await('telescopes:client:updateTelescopes', v)
    end
end

local function deleteTelescope(id)
    for _, v in pairs(GetPlayers()) do
        lib.callback.await('telescopes:client:delete', v, id)
    end
end

lib.callback.register('telescopes:server:getTelescopes', function(source)
    return telescopes
end)

lib.callback.register('telescopes:server:itemActions', function(source, telescope, action)
    local src = source
    if action == 'remove' then
        exports.ox_inventory:RemoveItem(src, telescope, 1)
    else
        exports.ox_inventory:AddItem(src, telescope, 1)
    end
end)

lib.callback.register('telescopes:server:place', function(source, telescope, coords, heading)
    local src = source
    coords = vec4(coords.x, coords.y, coords.z, heading)
    MySQL.insert('INSERT INTO `telescopes` (telescope, coords) VALUES (?, ?)', {
        telescope, json.encode(coords)
    }, function(id)
        telescopes[id] = { id = id, coords = coords, telescope = telescope }
        updateTelescopes()
    end)
    return true
end)

lib.callback.register('telescopes:server:delete', function(source, id)
    MySQL.Async.execute('DELETE FROM `telescopes` WHERE `id` = ?', { id }, function()
        telescopes[id] = nil
        deleteTelescope(id)
    end)
    return true
end)