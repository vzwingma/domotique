return
{
    on =
    {
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' },
        httpResponses = { 'Tydom_volets_setPosition' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Volets] "
    },
    execute = function(domoticz, item)
        -- Commande de thermostat
        if (item.isDevice) then
            
            -- Recherche du bon volet
            local deviceId = nil
            local endpointId = nil
            if(item.name == domoticz.helpers.DEVICE_VOLET_SALON_G) then
                deviceId=1612171343
                endpointId=1612171343
            elseif(item.name == domoticz.helpers.DEVICE_VOLET_SALON_D) then
                deviceId=1612171455
                endpointId=1612171455
            elseif(item.name == domoticz.helpers.DEVICE_VOLET_BEBE) then
                deviceId=1612171345
                endpointId=1612171343
            elseif(item.name == domoticz.helpers.DEVICE_VOLET_NOUS) then
                deviceId=1612171344
                endpointId=1612171343
            end
            
            
            -- Pourcentage de Commande
            local pOuverture = 100
            local level = 100
            if(item.state == 'Open') then
                pOuverture = 100
                level = 100
            elseif(item.state == 'Closed') then
                pOuverture = 80
                level = 0
            else
                pOuverture = item.state
            end
            
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value
            
            domoticz.log("[".. item.name .."] set Position=" .. pOuverture .. "%  (".. item.level .." -> " .. level .. ")")
            
            domoticz.openURL({
                    url = 'http://'..host_tydom_bridge..'/device/'..deviceId..'/endpoints/'..endpointId,
                    method = 'PUT',
                    header = { ['Content-Type'] = 'application/json' },
                    postData = { ['name'] = 'position', ['value'] = pOuverture },
                    callback = 'Tydom_volets_setPosition'
                })

        -- Callback
        elseif (item.isHTTPResponse) then
            local response = item
        --    domoticz.log(response, domoticz.LOG_DEBUG)
            domoticz.log('Response HTTP : ' .. response.statusCode .. " - " .. response.statusText)
            
        -- Catch exception
        else
            domoticz.log('There was an error', domoticz.LOG_ERROR)
        end        
    end       
}