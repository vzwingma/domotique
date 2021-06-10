return {
    on = {
        timer = { 'every 30 minutes' },
        devices = { 'MaJ Tydom Temperature' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Refresh] "
    },
    execute = function(domoticz, item)
        -- ### Appel de Tydom bridge pour refresh 
        if (item.isTimer or item.isDevice) then
            domoticz.helpers.callTydomBridgePOST('/refresh/all', domoticz)
        end
    end
}