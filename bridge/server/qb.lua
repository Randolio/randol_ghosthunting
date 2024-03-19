if GetResourceState('qb-core') ~= 'started' then return end

local QBCore = exports['qb-core']:GetCoreObject()
local ox_inv = GetResourceState('ox_inventory') == 'started'

function GetPlayer(id)
    return QBCore.Functions.GetPlayer(id)
end

function GetPlyIdentifier(Player)
    return Player.PlayerData.citizenid
end

function DoNotification(src, text, nType)
    TriggerClientEvent('QBCore:Notify', src, text, nType)
end

function GetCharacterName(Player)
    return Player.PlayerData.charinfo.firstname.. ' ' ..Player.PlayerData.charinfo.lastname
end

function AddMoney(Player, moneyType, amount)
    Player.Functions.AddMoney(moneyType, amount)
end

function itemCount(Player, item)
    local count = 0
    if ox_inv then 
        count = exports.ox_inventory:GetItemCount(Player.PlayerData.source, item)
    else
        for slot, data in pairs(Player.PlayerData.items) do -- Apparently qb only counts the amount from the first slot so I gotta do this.
            if data.name == item then
                count += data.amount
            end
        end
    end
    return count
end

function AddItem(Player, item, amount)
    if ox_inv then
        exports.ox_inventory:AddItem(Player.PlayerData.source, item, amount)
    else
        Player.Functions.AddItem(item, amount, false)
        TriggerClientEvent("inventory:client:ItemBox", Player.PlayerData.source, QBCore.Shared.Items[item], "add", amount)
    end
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    PlayerHasLoaded(source)
end)

if ox_inv then
    exports('ghostcam', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local src = inventory.id
            local player = GetPlayer(src)
            local cid = GetPlyIdentifier(player)
            if not ghostHunters[cid] then
                DoNotification(src, 'You need to speak to the priest at the cemetery to get started!', 'error')
                return false
            end
            TriggerClientEvent('randol_ghosts:client:useCamera', inventory.id)
        end
    end)
else
    QBCore.Functions.CreateUseableItem('ghostcam', function(source, item)
        local src = source
        local player = GetPlayer(src)
        local cid = GetPlyIdentifier(player)
        if not ghostHunters[cid] then
            DoNotification(src, 'You need to speak to the priest at the cemetery to get started!', 'error')
            return false
        end
        if player.Functions.GetItemByName(item.name) then
            TriggerClientEvent('randol_ghosts:client:useCamera', src)
        end
    end)
end