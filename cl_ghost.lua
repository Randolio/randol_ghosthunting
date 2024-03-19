local cachedLocations = {}
local storedPoints = {}
local ghosts = {}
local ptfxGhost = {}
local holdingCam = false
local fov_max = 80.0
local fov_min = 5.0 
local zoomspeed = 10.0
local speed_lr = 8.0
local speed_ud = 8.0
local fov = (fov_max+fov_min)*0.5
local cameraProp, PRIEST_PED, pedZone

RequestScriptAudioBank('DLC_MP2023_1/DLC_MP2023_1_GH', false, -1)

local function spawnPriest()
    if DoesEntityExist(PRIEST_PED) then return end
    
    lib.requestModel(`cs_priest`, 5000)
    PRIEST_PED = CreatePed(0, `cs_priest`, -1681.11, -291.01, 50.88, 239.09, false, false)
    SetEntityAsMissionEntity(PRIEST_PED)
    SetPedFleeAttributes(PRIEST_PED, 0, 0)
    SetBlockingOfNonTemporaryEvents(PRIEST_PED, true)
    SetEntityInvincible(PRIEST_PED, true)
    FreezeEntityPosition(PRIEST_PED, true)

    exports['qb-target']:AddTargetEntity(PRIEST_PED, {
        options = {
            {
                icon = 'fa-solid fa-ghost',
                label = 'Start Hunting',
                action = function()
                    lib.callback.await('randol_ghosts:server:startHunt', false)
                end,
            },
        },
        distance = 1.3
    })
end

local function yeetPriest()
    if not DoesEntityExist(PRIEST_PED) then return end
    exports['qb-target']:RemoveTargetEntity(PRIEST_PED, 'Start Hunting')
    DeleteEntity(PRIEST_PED)
    PRIEST_PED = nil
end

local function completedMessage(num, amount)
    local scaleform = lib.requestScaleformMovie('MIDSIZED_MESSAGE', 3000)
    BeginScaleformMovieMethod(scaleform, 'SHOW_COND_SHARD_MESSAGE')
    PushScaleformMovieMethodParameterString(('Ghosts Captured %s/5'):format(num))
    PushScaleformMovieMethodParameterString(('You captured a ghost on camera and received $%s'):format(amount))
    EndScaleformMovieMethod()
    PlaySoundFrontend(-1, 'Collect_Shard', 'Ghost_Hunt_Sounds', false)
    CreateThread(function()
        local sec = 5
        while sec > 0 do
            Wait(1)
            sec = sec - 0.01
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
        end
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end)
end

local function toggleCamera(bool)
    if bool then
        lib.requestAnimDict('amb@world_human_paparazzi@male@base', 2000)
        TaskPlayAnim(cache.ped, 'amb@world_human_paparazzi@male@base', 'base', 2.0, 2.0, -1, 1, 0, false, false, false)
        local pos = GetEntityCoords(cache.ped)
        local model = `prop_pap_camera_01`
        lib.requestModel(model, 5000)
        cameraProp = CreateObject(model, pos.x, pos.y, pos.z+0.2,  true,  true, true)
        AttachEntityToEntity(cameraProp, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(model)
    else
        if DoesEntityExist(cameraProp) then
            DeleteEntity(cameraProp)
            cameraProp = nil
            ClearPedTasks(cache.ped)
        end
    end
end

local function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
        if not IsPedSittingInAnyVehicle(cache.ped) then
            SetEntityHeading(cache.ped, new_z)
        end
    end
end

local function HandleZoom(cam)
    local lPed = cache.ped
    if not IsPedSittingInAnyVehicle(lPed) then
        if IsControlJustPressed(0,241) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0,242) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    else
        if IsControlJustPressed(0,17) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0,16) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    end
end

local function initCamera()
    holdingCam = true
    toggleCamera(true)
    lib.showTextUI(('**LEFT CLICK** - %s  \n**SCROLL** - %s  \n**BACKSPACE** - %s'):format('Take Photo', 'Zoom In/Out', 'Cancel'), {position = 'left-center'})
    CreateThread(function()
        Wait(100)

        SetTimecycleModifier('default')
        SetTimecycleModifierStrength(0.3)

        local cam = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)
        AttachCamToEntity(cam, cache.ped, 0.0, 1.0, 0.8, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(cache.ped), 2)
        SetCamFov(cam, fov)
        RenderScriptCams(true, false, 0, true, false)

        while holdingCam and not IsEntityDead(cache.ped) do
            DisablePlayerFiring(cache.playerId, true)
            if IsControlJustPressed(0, 177) then
                holdingCam = false
                PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                ClearPedTasks(cache.ped)
            elseif IsControlJustPressed(1, 176) then
                PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', false)
                if closestGhost and IsEntityOnScreen(closestGhost) then
                    local success, num, amount = lib.callback.await('randol_ghosts:server:ghostCaught', false, GetEntityModel(closestGhost))
                    if num and amount then
                        completedMessage(num, amount)
                    end
                end
                holdingCam = false
                ClearPedTasks(cache.ped)
            end

            local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
            CheckInputRotation(cam, zoomvalue)
            HandleZoom(cam)
            Wait(0)
        end
        lib.hideTextUI()
        toggleCamera(false)
        holdingCam = false
        ClearTimecycleModifier()
        fov = (fov_max + fov_min) * 0.5
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        SetNightvision(false)
        SetSeethrough(false)
    end)
end

function cleanup()
    for i = 1, #storedPoints do
        if storedPoints[i] then storedPoints[i]:remove() end
    end
    for k, _ in pairs(ghosts) do
        if DoesEntityExist(ghosts[k]) then
            StopParticleFxLooped(ptfxGhost[k], true)
            DeleteEntity(ghosts[k])
            ptfxGhost[k] = nil
            ghosts[k] = nil
        end
    end
    if pedZone then pedZone:remove() pedZone = nil end
    yeetPriest()
    table.wipe(cachedLocations)
    table.wipe(storedPoints)
end

local function yeetGhost(data)
    if DoesEntityExist(ghosts[data.index]) then
        StopParticleFxLooped(ptfxGhost[data.index], true)
        DeleteEntity(ghosts[data.index])
        ghosts[data.index] = nil
        ptfxGhost[data.index] = nil
        closestGhost = nil
    end
end

local function nearGhost(data)
    local currentHour = GetClockHours()
    if currentHour >= 23 or currentHour < 2 then
        if not DoesEntityExist(ghosts[data.index]) then
            local v = data.pedData
            local model = joaat(v.model)
            lib.requestModel(model, 5000)
            ghosts[data.index] = CreateObject(model, v.coords.x, v.coords.y, v.coords.z - 0.85, false, false, false)
            closestGhost = ghosts[data.index]
            SetEntityHeading(ghosts[data.index], v.coords.w-180.0)
            FreezeEntityPosition(ghosts[data.index], true)
            lib.requestAnimDict('ANIM@SCRIPTED@FREEMODE@IG2_GHOST@', 2000)
            PlayEntityAnim(ghosts[data.index], 'float_1', 'ANIM@SCRIPTED@FREEMODE@IG2_GHOST@', 1000.0, true, true, true, 0, 136704)
            lib.requestNamedPtfxAsset('scr_srr_hal', 5000)
            UseParticleFxAsset('scr_srr_hal')
            ptfxGhost[data.index] = StartParticleFxLoopedOnEntity('scr_srr_hal_ghost_haze', ghosts[data.index], 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 1.0, false, false, false)
            SetParticleFxLoopedEvolution(ptfxGhost[data.index], 'smoke', 10.0, true)
        end
    else
        if currentHour >= 2 and currentHour < 23 then
            if DoesEntityExist(ghosts[data.index]) then
                StopParticleFxLooped(ptfxGhost[data.index], true)
                DeleteEntity(ghosts[data.index])
                ghosts[data.index] = nil
                ptfxGhost[data.index] = nil
                closestGhost = nil
            end
        end
    end
end

local function createGhostSpawns()
    for id, data in pairs(cachedLocations) do
        local zone = lib.points.new({
            coords = data.coords,
            distance = 50,
            index = id,
            pedData = data,
            nearby = nearGhost,
            onExit = yeetGhost,
        })
        storedPoints[#storedPoints+1] = zone
    end
    pedZone = lib.points.new({
        coords = vec3(-1681.11, -291.01, 50.88),
        distance = 50,
        onEnter = spawnPriest,
        onExit = yeetPriest,
    })
end

RegisterNetEvent('randol_ghosts:client:cacheLocations', function(data)
    if GetInvokingResource() or not hasPlyLoaded() then return end
    cachedLocations = data
    createGhostSpawns()
end)

AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then return end
    cleanup()
end)

RegisterNetEvent('randol_ghosts:client:useCamera', function()
    if GetInvokingResource() or holdingCam then return end
    initCamera()
end)