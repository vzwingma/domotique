return {
    on = {
        timer = { 'every 12 minutes' },
        devices = { 'MaJ Tydom Temperature' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Refresh] "
    },
    execute = function(domoticz, item)
        -- ### Appel de Tydom bridge pour refresh 
        if (item.isTimer or item.isDevice) then
            domoticz.log("Rafraichissement des valeurs de Tydom", domoticz.LOG_DEBUG)
            domoticz.helpers.callTydomBridgePOST('/refresh/all', domoticz)
        end
    end
}