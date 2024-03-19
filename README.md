# Randolio: Ghost Hunting

**ESX/QB/ND supported with bridge**

A little ghost hunt minigame inspired from GTA online that can occur every server restart. All 5 ghosts will be randomly generated at set coordinates until your server restarts or you restart the resource. Player's can only do it once per server restart on that specific character. Small cash rewards per photo captured, adjust if you want. Add more locations, whatever! There is only 5 ghost models so don't touch those.

## Requirements

* [ox_lib](https://github.com/overextended/ox_lib/releases/)

## Items 

if qb-inventory then navigate to: qb-core/shared/items.lua
```lua
ghostcam = { name = 'ghostcam', label = 'Ghost Camera', weight = 100, type = 'item', image = 'ghostcam.png', unique = false, useable = true, shouldClose = true, combinable = nil, description = 'A camera for capturing spookies.' },
```

if ox_inventory then put this in your items.lua
```lua
['ghostcam'] = {
    label = 'Ghost Camera',
    weight = 100,
    stack = true,
    close = true,
    consume = 0,
    description = 'A camera for capturing spookies.',
    server = {
        export = 'randol_ghosthunting.ghostcam',
    },
},
```

* [preview](https://streamable.com/iha0b7)

**You have permission to use this in your server and edit for your personal needs but are not allowed to redistribute.**