if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

local PlayerData = {}

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    table.wipe(PlayerData)
    ESX.PlayerLoaded = false
    cleanup()
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res or not ESX.PlayerLoaded then return end

    PlayerData = ESX.PlayerData
end)

AddEventHandler('esx:setPlayerData', function(key, value)
	PlayerData[key] = value
end)

function isPlyDead()
    return PlayerData.dead
end

function hasPlyLoaded()
    return ESX.PlayerLoaded
end

function DoNotification(text, nType)
    lib.notify({ title = "Notification", description = text, type = nType, })
end
