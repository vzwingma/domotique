-- ## Scripts de lecture des éléments issus du service Devices.Device.HGW de la Livebox

return {
    on = {
        httpResponses = { 'livebox_wan_statuts' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[ORANGE Livebox] "
    },
    execute = function(domoticz, item)
        
    -- #### Fonctions de lecture des statuts
    
    -- ## Déclenchement de la fonction
        domoticz.log(item.statusCode .. " - " .. item.statusText)
            
        if (item.ok) then -- statusCode == 2xx
            local contextId = item.json
            domoticz.log(contextId)
        end

    end
}