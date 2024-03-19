ghostHunters = {}
local generatedLocs = {}
local ghostLocations = {
    vec4(-1071.77, 9.53, 52.27, 81.28),
    vec4(346.68, -199.12, 58.02, 126.6),
    vec4(389.55, -356.32, 48.02, 278.32),
    vec4(473.61, -977.88, 27.98, 325.11),
    vec4(1080.08, -701.41, 58.79, 304.35),
    vec4(1656.01, -49.61, 168.36, 87.72),
    vec4(1979.41, 3817.95, 32.55, 264.13),
    vec4(2443.42, 4963.89, 51.57, 184.93),
    vec4(1340.2, 4224.83, 33.91, 251.14),
    vec4(166.09, 6632.31, 31.54, 189.75),
    vec4(439.41, 6504.99, 28.76, 66.82),
}

local function doShuffle(locs)
    local size = #locs
    for i = size, 1, -1 do
        local rand = math.random(size)
        locs[i], locs[rand] = locs[rand], locs[i]
    end
    return locs
end

local function generateGhosts()
    local locs = doShuffle(ghostLocations)
    local ghosts = {
        'm23_1_prop_m31_ghostsalton_01a',
        'm23_1_prop_m31_ghostskidrow_01a',
        'm23_1_prop_m31_ghostzombie_01a',
        'm23_1_prop_m31_ghostrurmeth_01a',
        'm23_1_prop_m31_ghostjohnny_01a',
    }

    for index, model in ipairs(ghosts) do
        local location = locs[index]

        generatedLocs[#generatedLocs+1] = {model = model, coords = location}
    end

    --print(json.encode(generatedLocs, {indent = true})) -- incase you need to debug the locations.
end

local function isNearGhost(model, pos)
    for _, v in ipairs(generatedLocs) do
        if joaat(v.model) == model and #(pos - v.coords.xyz) < 20.0 then
            return true
        end
    end
    return false
end

lib.callback.register('randol_ghosts:server:ghostCaught', function(source, model)
    if not source or not model then return false end

    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)
    local pos = GetEntityCoords(GetPlayerPed(src))
    local isNear = isNearGhost(model, pos)

    if not ghostHunters[cid] then
        DoNotification(src, 'You need to speak to the priest at the cemetery!', 'error')
        return false
    end

    if not isNear then
        DoNotification(src, 'You are too far from the ghost.', 'error')
        return false 
    end

    if ghostHunters[cid][model] then
        DoNotification(src, 'You have already photographed this ghost today.', 'error')
        return false
    end

    ghostHunters[cid][model] = true
    ghostHunters[cid].completed += 1

    local amount = math.random(2500, 3750)
    AddMoney(player, 'cash', amount)
    
    return true, ghostHunters[cid].completed, amount
end)

lib.callback.register('randol_ghosts:server:startHunt', function(source)
    if not source then return false end

    local src = source
    local player = GetPlayer(src)
    local cid = GetPlyIdentifier(player)
    
    if ghostHunters[cid] then 
        DoNotification(src, 'You have already started/completed your ghost hunt today.', 'error')
        return false 
    end

    if itemCount(player, 'ghostcam') == 0 then
        AddItem(player, 'ghostcam', 1)
    end

    ghostHunters[cid] = { completed = 0 }
    DoNotification(src, 'Go find the 5 ghosts and snap photos for proof!', 'success')
    return true
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res then return end
    generateGhosts()
    SetTimeout(2000, function()
        TriggerClientEvent('randol_ghosts:client:cacheLocations', -1, generatedLocs)
    end)
end)

function PlayerHasLoaded(source)
    local src = source
    SetTimeout(2000, function()
        TriggerClientEvent('randol_ghosts:client:cacheLocations', src, generatedLocs)
    end)
end