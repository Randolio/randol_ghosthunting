if not lib.checkDependency('ND_Core', '2.0.0') then return end

NDCore = {}

lib.load('@ND_Core.init')

function GetPlayer(id)
    return NDCore.getPlayer(id)
end

function GetPlyIdentifier(Player)
    return Player.id
end

function DoNotification(src, text, nType)
    TriggerClientEvent('ox_lib:notify', src, { type = nType, description = text })
end

function GetCharacterName(Player)
    return Player.fullname
end

function AddMoney(Player, moneyType, amount)
    Player.addMoney(moneyType, amount)
end

function itemCount(Player, item, amount)
    return exports.ox_inventory:GetItemCount(Player.source, item)
end

function AddItem(Player, item, amount)
    exports.ox_inventory:AddItem(Player.source, item, amount)
end

AddEventHandler("ND:characterLoaded", function(character)
    PlayerHasLoaded(character.source)
end)

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
