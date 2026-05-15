local config = require 'config.client'

-- Variables --
local inTelescope = false
local isPlacingObject = false
local gameplayCamera = {}
local telescopeHeading = 0.0
local frozen = false

local camera = 0
local scaleform = 0

local fov = config.zoom.max
local relativeOffset = 0.0
local maxVertical = 20.0
local maxHorizontal = 55.0

local telescopes = {}
local prop = nil

local hudComponentsToHide = {
    [1] = true, -- Wanted Stars
    [2] = true, -- Weapon icon
    [3] = true, -- Cash
    [4] = true, -- MP CASH
    [13] = true, -- Cash Change
    [11] = true, -- Floating Help Text
    [12] = true, -- More floating help text
    [15] = true, -- Subtitle Text
    [18] = true, -- Game Stream
    [19] = true -- Weapon Wheel
}

-- Functions --
local function rotationToDirection(rotation)
	local adjustedRotation = { x = (math.pi / 180) * rotation.x, y = (math.pi / 180) * rotation.y, z = (math.pi / 180) * rotation.z }
	local direction = { x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), z = math.sin(adjustedRotation.x) }
	return direction
end

local function rayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = rotationToDirection(cameraRotation)
	local destination = { x = cameraCoord.x + direction.x * distance, y = cameraCoord.y + direction.y * distance, z = cameraCoord.z + direction.z * distance }
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, cache.ped, 0))
	return destination
end

local function Notification(data)
    lib.notify({
        title = locale('notification.title'),
        description = data.description,
        type = data.type,
        duration = data.duration
    })
end

local function ShowText(data)
    lib.showTextUI(data.text, {
        position = data.position,
        icon = data.icon or 'fa-solid fa-arrow-right-from-bracket'
    })
end

local function HideText()
    lib.hideTextUI()
end

local function SetupInstructions()
    ShowText({text = locale('interaction.prompt_exit'), position = 'right-center'})
end

local function CreateTelescopeCamera(entity, data)
    camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local coords = GetOffsetFromEntityInWorldCoords(entity, data.cameraOffset.x, data.cameraOffset.y, data.cameraOffset.z)
    local rotation = GetEntityRotation(entity, 5).z
    if data.headingOffset then
        rotation = rotation + data.headingOffset
        if rotation > 360.0 then rotation = rotation - 360.0 end
    end

    SetCamCoord(camera, coords.x, coords.y, coords.z)
    SetCamRot(camera, 0.0, 0.0, rotation, 2)

    SetExtraTimecycleModifier("telescope")

    scaleform = RequestScaleformMovie(data.scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(0)
    end

    local xRes, yRes = GetActiveScreenResolution()
    BeginScaleformMovieMethod(scaleform, "SET_DISPLAY_CONFIG")
    ScaleformMovieMethodAddParamInt(xRes)
    ScaleformMovieMethodAddParamInt(yRes)
    ScaleformMovieMethodAddParamInt(5) --_safeTopPercent
    ScaleformMovieMethodAddParamInt(5) --_safeBottomPercent
    ScaleformMovieMethodAddParamInt(5) --_safeLeftPercent
    ScaleformMovieMethodAddParamInt(5) --_safeRightPercent
    ScaleformMovieMethodAddParamBool(GetIsWidescreen())
    ScaleformMovieMethodAddParamBool(GetIsHidef())
    ScaleformMovieMethodAddParamBool(false) --isAsian
    EndScaleformMovieMethod()

    RenderScriptCams(true, false, 0, false, false)
end

local function HideHudThisFrame()
    HideHudAndRadarThisFrame()
    for id, _state in pairs(hudComponentsToHide) do
        HideHudComponentThisFrame(id)
    end
end

local function IsPedPlayingAnyTelescopeAnim(ped)
    for _animType, animations in pairs(config.animations) do
        for _key, animation in pairs(animations) do
            if type(animation) == "string" and IsEntityPlayingAnim(ped, "mini@telescope", animation, 3) then
                return true
            end
        end
    end
    return false
end

local function IsTelescopeAvailable(coords)
    local pedPool = GetGamePool('CPed')
    for _index, ped in pairs(pedPool) do
        if #(GetEntityCoords(ped) - coords) < 1.0 and ped ~= cache.ped then
            if IsPedPlayingAnyTelescopeAnim(ped) then
                return false
            end
        end
    end

    return true
end

local function HandleZoom()
    if GetDisabledControlNormal(0, 32) ~= 0.0 or GetDisabledControlNormal(0, 335) ~= 0.0 then -- Zoom in
        fov = math.max(fov - config.zoom.speed, config.zoom.min)
    end

    if GetDisabledControlNormal(0, 33) ~= 0.0 or GetDisabledControlNormal(0, 336) ~= 0.0 then -- Zoom out
        fov = math.min(fov + config.zoom.speed, config.zoom.max)
    end

    local current_fov = GetCamFov(camera)
    if math.abs(fov-current_fov) < 0.1 then
        fov = current_fov
    end

    SetCamFov(camera, current_fov + (fov - current_fov)*0.05)
end

local function HandleMovementInput()
    local axisX = GetDisabledControlNormal(0, 220)
    local axisY = GetDisabledControlNormal(0, 221)

    if axisX ~= 0.0 or axisY ~= 0.0 then
        local zoomValue = (1.0/(config.zoom.max-config.zoom.min))*(fov-config.zoom.min)
        local rotation = GetCamRot(camera, 2)

        local movementSpeed = (IsUsingKeyboard(1) and config.movementSpeed.keyboard) or config.movementSpeed.controller
        relativeOffset = relativeOffset + axisX*-1.0*(movementSpeed)*(zoomValue+0.1)
        if relativeOffset > maxHorizontal then
            relativeOffset = maxHorizontal
        elseif relativeOffset < maxHorizontal*-1 then
            relativeOffset = maxHorizontal*-1
        end

        local newX = math.max(math.min(maxVertical, rotation.x + axisY*-1.0*(movementSpeed)*(zoomValue+0.1)), maxVertical*-1)
        local newZ = telescopeHeading + relativeOffset

        SetCamRot(camera, newX, 0.0, newZ, 2)
    end
end

local function GetClosestTelescope()
    local objectPool = GetGamePool('CObject')
    local telescopes = {}
    for _index, entity in pairs(objectPool) do
        local model = GetEntityModel(entity)
        if config.models[model] then
            telescopes[entity] = true
        end
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local closest = 0
    local distance = 1000

    for entity, _boolean in pairs(telescopes) do
        local coords = GetEntityCoords(entity)
        local dist = #(playerCoords - coords)
        if dist < distance then
            closest = entity
            distance = dist
        end
    end

    return closest, distance
end

local function RequestControlIfNetworked(entity)
    if NetworkGetEntityIsNetworked(entity) then
        NetworkRequestControlOfEntity(entity)
    end
end

local function FreezeTelescope(entity)
    if not IsEntityPositionFrozen(entity) then
        RequestControlIfNetworked(entity)
        FreezeEntityPosition(entity, true)
        frozen = true
    end
end

local function UnfreezeTelescope(entity)
    if frozen then
        RequestControlIfNetworked(entity)
        FreezeEntityPosition(entity, false)
        frozen = false
    end
end

local function GetEntityTilt(entity)
    local rot = GetEntityRotation(entity)
    local xRot = rot.x
    local yRot = rot.y

    if xRot < 0.0 then xRot = xRot*-1 end
    if yRot < 0.0 then yRot = yRot*-1 end

    return xRot + yRot
end

local function InteractTelescope(entity)
    if GetEntityTilt(entity) > config.maxTilt then
        Notification({description = locale('notification.too_tilted'), duration = 7500, type = 'error'})
        return
    end

    local data = config.models[GetEntityModel(entity)]
    local offsetCoords = GetOffsetFromEntityInWorldCoords(entity, data.offset.x, data.offset.y, data.offset.z)
    if not IsTelescopeAvailable(offsetCoords) then
        Notification({description = locale('notification.in_use'), duration = 7500, type = 'error'})
        return
    end

    inTelescope = true

    local heading = GetEntityHeading(entity)
    if data.headingOffset then
        heading = heading + data.headingOffset
        if heading > 360.0 then heading = heading - 360.0 end
    end

    TaskGoStraightToCoord(cache.ped, offsetCoords.x, offsetCoords.y, offsetCoords.z, 1, 8000, heading, 0.05)

    while true do
        Wait(250)
        local taskStatus = GetScriptTaskStatus(cache.ped, "SCRIPT_TASK_GO_STRAIGHT_TO_COORD")
        if taskStatus == 0 or taskStatus == 7 then
            break
        end
    end

    ClearPedTasks(cache.ped)
    local difference = math.abs(heading - GetEntityHeading(cache.ped))
    if difference > 10.0 then
        SetEntityHeading(cache.ped, heading)
    end

    local dist = #(GetEntityCoords(cache.ped)-offsetCoords)
    if dist > 0.425 and dist < 2.0 then
        SetEntityCoords(cache.ped, offsetCoords.x, offsetCoords.y, offsetCoords.z-1.0)
    elseif dist > 2.0 then
        Notification({description = locale('notification.too_far'), duration = 7500, type = 'error'})
        ClearPedTasks(cache.ped)
        inTelescope = true
        return
    end

    FreezeTelescope(entity)

    local animation = config.animations[data.animation]

    if not animation then
        print('[telescope] animation missing in config')
        return
    end

    lib.playAnim(cache.ped, "mini@telescope", animation.enter, 2.0, 2.0, -1, 2, 0, false, false, false)

    gameplayCamera.heading = GetGameplayCamRelativeHeading()
    gameplayCamera.pitch = GetGameplayCamRelativePitch()

    Wait(animation.enterTime)
    DoScreenFadeOut(500)
    Wait(600)

    lib.playAnim(cache.ped, "mini@telescope", animation.idle, 2.0, 2.0, -1, 1, 0, false, false, false)
    CreateTelescopeCamera(entity, data)
    SetupInstructions()

    CreateThread(function()
        DoScreenFadeIn(500)
    end)

    local tick = 0
    local doAnim = true

    fov = config.zoom.max
    maxVertical = data.MaxVertical
    maxHorizontal = data.MaxHorizontal
    telescopeHeading = heading
    relativeOffset = 0.0

    while true do
        -- Handle the movement and button inputs every frame
        HandleZoom()
        HandleMovementInput()

        if IsControlJustPressed(0, 38) then
            break
        end

        -- Only handle "less important" stuff every 100 frames
        if tick >= 100 then
            if #(GetEntityCoords(cache.ped)-offsetCoords) > 1.5 or IsEntityDead(cache.ped) then
                doAnim = false
                break
            end
            tick = 0
        end

        -- Draw the scaleform
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)

        -- Hide hud
        HideHudThisFrame()

        tick = tick + 1
        Wait(0)
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
        Wait(0)
    end
    Wait(150)

    RenderScriptCams(false, false, 0, false, false)
    DestroyCam(camera, false)

    ClearExtraTimecycleModifier()
    SetScaleformMovieAsNoLongerNeeded(scaleform)

    SetGameplayCamRelativeHeading(gameplayCamera.heading)
    SetGameplayCamRelativePitch(gameplayCamera.pitch, 1.0)

    DoScreenFadeIn(500)
    Wait(500)

    if doAnim then
        lib.playAnim(cache.ped, "mini@telescope", animation.exit, 2.0, 1.0, -1, 0, 0, false, false, false)
        Wait(1500)
    else
        ClearPedTasks(cache.ped)
        HideText()
    end

    if not config.target == false then
        HideText()
    end

    inTelescope = false
    UnfreezeTelescope(entity)
end


-- Targeting --
if config.target then
    local models = {}
    for model, _data in pairs(config.models) do
        models[#models+1] = model
    end

    if config.target == "ox_target" then
        exports.ox_target:addModel(models, {
            {
                icon = config.targeting.icon,
                label = locale('interaction.target_use'),
                distance = config.maxInteractionDist,
                onSelect = function(data)
                    if not isPlacingObject then
                        InteractTelescope(data.entity)
                    end
                end
            }
        })
    else
        exports[config.target]:AddTargetModel(models, {
            options = {
                {
                    icon = config.targeting.icon,
                    label = locale('interaction.target_use'),
                    action = function(entity)
                        if not isPlacingObject then
                            InteractTelescope(entity)
                        end
                    end
                }
            },
            distance = config.maxInteractionDist
        })
    end
end


-- Help Text Thread --
if config.useDistanceThread then
    local telescopes = {}

    CreateThread(function()
        while true do
            local objectPool = GetGamePool('CObject')
            for _index, entity in pairs(objectPool) do
                local model = GetEntityModel(entity)
                if config.models[model] then
                    telescopes[entity] = true
                end
            end

            Wait(1000)
        end
    end)

    CreateThread(function()
        while true do
            if not inTelescope and not isPlacingObject then
                local playerCoords = GetEntityCoords(cache.ped)
                local closest = 0
                local distance = 250

                for entity, _boolean in pairs(telescopes) do
                    local coords = GetEntityCoords(entity)
                    local dist = #(playerCoords - coords)
                    if dist < distance then
                        closest = entity
                        distance = dist
                    end
                end

                if closest ~= 0 and distance < config.maxInteractionDist then
                    if config.marker.enabled then
                        local coords = GetEntityCoords(closest)
                        local model = GetEntityModel(closest)
                        DrawMarker(config.marker.type, coords.x, coords.y, coords.z + config.models[model].markerHeight, 0.0, 0.0, 0.0, config.marker.rotX, config.marker.rotY, config.marker.rotZ, config.marker.scale.x, config.marker.scale.y, config.marker.scale.z, config.marker.color.r, config.marker.color.g, config.marker.color.b, config.marker.color.a, config.marker.bobUpAndDown, config.marker.faceCamera, config.marker.rotationOrder, config.marker.rotate, config.marker.textureDict, config.marker.textureName, config.marker.drawOnEnts)
                    end
                    if config.target == false then
                        ShowText({text = locale('interaction.prompt_use'), position = 'right-center', icon = config.targeting.icon})
                    end
                    if IsControlJustPressed(0, 38) then
                        InteractTelescope(closest)
                    end
                    Wait(0)
                else
                    HideText()
                    Wait(distance*5)
                end
            else
                Wait(500)
            end
        end
    end)
end

local function UseTelescope(data, item)
    isPlacingObject = true
    ShowText({text = locale('placement.controls'), position = 'right-center'})
    lib.callback.await('telescopes:server:itemActions', false, item.name, 'remove')
    local prop = CreateObject(GetHashKey(config.useItem[item.name]), 0, 0, 0, false, false, false)
    local heading = GetEntityHeading(prop)
    SetEntityAlpha(prop, 150, false)
    SetEntityCollision(prop, false, false)

    CreateThread(function()
        while isPlacingObject do
            Wait(0)
            local coords = rayCastGamePlayCamera(4.0)
            SetEntityCoords(prop, coords.x, coords.y, coords.z, heading, false, false, false)
            PlaceObjectOnGroundProperly(prop)

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            if IsControlPressed(0, 15) then
                heading += 1.0
                SetEntityHeading(prop, heading)
            elseif IsControlPressed(0, 14) then
                heading -= 1.0
                SetEntityHeading(prop, heading)
            end

            if IsControlPressed(0, 176) then
                if lib.progressCircle({
                    duration = 1000,
                    position = 'bottom',
                    label = locale('placement.progress_label'),
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true, 
                        combat = true,
                    },
                    anim = {
                        dict = 'pickup_object',
                        clip = 'pickup_low',
                        flag = 16,
                    },
                    prop = {
                        model = config.useItem[item.name],
                        bone = 28422,
                        pos = vec3(0.05, 0.05, 0.0),
                        rot = vec3(0.0, 0.0, 180.0)
                    },
                }) then
                    DeleteObject(prop)
                    DeleteEntity(prop)
                    HideText()
                    lib.callback.await('telescopes:server:place', false, item.name, coords, heading)
                    break
                else
                    DeleteObject(prop)
                    DeleteEntity(prop)
                    HideText()
                    lib.callback.await('telescopes:server:itemActions', false, item.name, 'add')
                    break
                end
            elseif IsControlPressed(0, 177) then
                DeleteObject(prop)
                DeleteEntity(prop)
                HideText()
                lib.callback.await('telescopes:server:itemActions', false, item.name, 'add')
                break
            end
        end
        isPlacingObject = false
    end)
end

exports('UseTelescope', UseTelescope)

local function deleteTelescope(id, item)
    if lib.progressCircle({
        duration = 1500,
        position = 'bottom',
        label = locale('placement.collect_label'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = 'pickup_object',
            clip = 'pickup_low',
            flag = 16,
        },
    }) then
        lib.callback.await('telescopes:server:delete', false, id)
        lib.callback.await('telescopes:server:itemActions', false, item, 'add')
    else
        Notification({description = locale('notification.cancelled'), duration = 7500, type = 'error'})
    end
end

local function spawnAllTelescopes()
    local svTelescopes = lib.callback.await('telescopes:server:getTelescopes')
    for k, v in pairs(svTelescopes) do
        if telescopes[v.id] then goto continue end

        local prop = CreateObject(GetHashKey(config.useItem[v.telescope]), v.coords.x, v.coords.y, v.coords.z, false, false, false)
        SetEntityHeading(prop, v.coords.w)
        PlaceObjectOnGroundProperly(prop)
        Wait(200)
        FreezeEntityPosition(prop, true)

        telescopes[k] = v
        telescopes[k].prop = prop

        exports.ox_target:addLocalEntity(prop, {
            {
                label = locale('interaction.target_collect'),
                icon = 'fas fa-hand-paper',
                onSelect = function()
                    if not inTelescope and not isPlacingObject then
                        deleteTelescope(k, v.telescope)
                    end
                end
            }
        })

        :: continue ::
    end
end

local function despawnAllTelescopes()
    for _, v in pairs(telescopes) do
        DeleteObject(v.prop)
        DeleteEntity(v.prop)
    end
    telescopes = {}
end

lib.callback.register('telescopes:client:updateTelescopes', function()
    spawnAllTelescopes()
end)

lib.callback.register('telescopes:client:delete', function(id)
    if telescopes[id] then
        DeleteObject(telescopes[id].prop)
        DeleteEntity(telescopes[id].prop)
        telescopes[id] = nil
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(500)
    spawnAllTelescopes()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    despawnAllTelescopes()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    spawnAllTelescopes()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    despawnAllTelescopes()
end)

-- Commands --
RegisterNetEvent('telescopes:client:InteractTelescope', function()
    if isPlacingObject then return end
    local telescope, distance = GetClosestTelescope()
    if telescope ~= 0 and distance < config.maxInteractionDist then
        InteractTelescope(telescope)
    else
        Notification({description = locale('notification.not_found'), duration = 7500, type = 'error'})
    end
end)