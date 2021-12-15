return {
    on = {
        timer = { 'every 12 minutes' },
        devices = { 'MaJ Tydom Temperature' }
    },
    logging = {
        level = domoticz.LOG_ERROR,
        marker = "[TYDOM Refresh] "
    },
    execute = function(domoticz, item)
        -- ### Appel de Tydom bridge pour refresh 
        local uuid = domoticz.helpers.uuid()
        if (item.isTimer or item.isDevice) then
            domoticz.log("[" .. uuid .. "] Rafraichissement des valeurs de Tydom", domoticz.LOG_DEBUG)
            domoticz.helpers.callTydomBridgePOST('/refresh/all', uuid, domoticz)
        end
    end
}