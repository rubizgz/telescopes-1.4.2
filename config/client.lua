return {
    --[[ 
        Interaction system used to trigger telescope usage.

        Options:
        - 'ox_target'  : ox_target interaction system
        - 'qTarget'    : qTarget system
        - 'qb-target'  : qb-target system
        - false        : disables target system and uses distance-based detection

        NOTE: If set to false, you MUST enable useDistanceThread.
    ]]
    target = 'ox_target',

    -- Marker: https://docs.fivem.net/docs/game-references/markers/
    -- Color: https://docs.fivem.net/docs/game-references/hud-colors/
    marker = {
        enabled = true,                            -- Enable or disable the marker above the telescope
        type = 21,                                 -- Marker type
        scale = {x = 0.1, y = 0.1, z = 0.1},       -- Scale of the marker (X, Y, Z)
        color = {r = 0, g = 255, b = 80, a = 200}, -- RGBA color
        bobUpAndDown = true,                       -- Native GTA bounce animation
        faceCamera = true,                         -- Marker always faces the player camera
        rotationOrder = 2,                         -- Rotation order
        rotX = 0.0,                                -- X Rotation
        rotY = 180.0,                              -- Y Rotation
        rotZ = 0.0,                                -- Z Rotation
        rotate = false,                            -- Enable continuous rotation
        textureDict = nil,                         -- Custom texture dictionary
        textureName = nil,                         -- Custom texture name
        drawOnEnts = false                         -- Whether the marker should draw on intersecting entities
    },

    targeting = {
        icon = 'fas fa-binoculars', -- Icon displayed in target / interaction UI
    },

    -- Enables proximity-based interaction detection (required when target = false)
    useDistanceThread = false,

    -- Maximum distance (in meters) allowed to interact with a telescope
    maxInteractionDist = 1.75,

    -- Maximum tilt angle allowed before interaction is blocked (prevents unrealistic usage)
    maxTilt = 20.0,

    movementSpeed = {
        -- Camera rotation sensitivity when using keyboard/mouse
        keyboard = 2.75,

        -- Camera rotation sensitivity when using a controller
        controller = 1.0
    },

    zoom = {
        max = 50.0,  -- Maximum FOV (fully zoomed out / wide view)
        min = 5.0,   -- Minimum FOV (fully zoomed in / narrow view)
        speed = 5.0  -- Speed at which zoom transitions change
    },

    animations = {
        default = {
            enter = "enter_front",         -- Played when starting telescope interaction
            enterTime = 1500,              -- Time before switching to idle animation
            exit = "exit_front",           -- Played when exiting telescope
            idle = "idle"                  -- Loop animation while using telescope
        },

        public = {
            enter = "public_enter_front",
            enterTime = 1500,
            exit = "public_exit_front",
            idle = "public_idle"
        },

        upright = {
            enter = "upright_enter_front",
            enterTime = 2500,
            exit = "upright_exit_front",
            idle = "upright_idle"
        }
    },

    models = {
        --[[ Public street telescope ]]
        [`prop_telescope_01`] = {
            MaxHorizontal = 55.0,                   -- Max horizontal camera rotation
            MaxVertical = 20.0,                     -- Max vertical camera rotation
            offset = vector3(-0.03, 0.96, 0.0),     -- Player position offset relative to object
            headingOffset = 180.0,                  -- Adjusts telescope orientation alignment
            animation = "public",                   -- Animation set used for this model
            cameraOffset = vector3(0.0, -0.5, 0.7), -- Camera position relative to telescope
            scaleform = "OBSERVATORY_SCOPE",        -- UI overlay style
            markerHeight = 1.0                      -- Vertical offset above the telescope (adjust according to prop size)
        },

        --[[ Mount Chiliad telescope ]]
        [`prop_telescope`] = {
            MaxHorizontal = 55.0,
            MaxVertical = 20.0,
            offset = vector3(0.02, -0.78, 1.0),
            animation = "upright",
            cameraOffset = vector3(0.0, 0.2, 1.7),
            scaleform = "BINOCULARS",
            markerHeight = 1.0
        },

        --[[ Domestic/private telescope ]]
        [`prop_t_telescope_01b`] = {
            MaxHorizontal = 55.0,
            MaxVertical = 35.0,
            offset = vector3(1.14, 0.0, 0.0),
            headingOffset = 90.0,
            animation = "default",
            cameraOffset = vector3(-0.25, 0.0, 1.3),
            scaleform = "OBSERVATORY_SCOPE",
            markerHeight = 1.2
        },

        --[[ Arena telescope ]]
        [`xs_prop_arena_telescope_01`] = {
            MaxHorizontal = 55.0,
            MaxVertical = 20.0,
            offset = vector3(-0.03, 0.96, 0.0),
            headingOffset = 180.0,
            animation = "public",
            cameraOffset = vector3(0.0, -0.5, 0.7),
            scaleform = "BINOCULARS",
            markerHeight = 1.0
        }
    }
}