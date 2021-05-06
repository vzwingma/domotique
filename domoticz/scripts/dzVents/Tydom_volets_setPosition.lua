return
{
    on =
    {
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' },
        scenes = { 'Reveil' },
        httpResponses = { 'Tydom_volets_setPosition' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Volets] "
    },
    execute = function(domoticz, item)
        
        local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value
        domoticz.log('Capture Event')
        local deviceId = nil
        local endpointId = nil
        local pOuverture = 0
        local voletName = 'UKN'
        
        -- Commande de volets
        if (item.isDevice) then
            -- Recherche du bon volet
            voletName = item.name
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
            domoticz.log(" State="..item.state..", level="..item.level)
            -- Pourcentage de Commande
            -- Réaligné par rapport à létat
            if(item.state == 'Off' and item.level ~= 0) then
               item.setLevel(0)
            else
                pOuverture = item.level
            end
        -- Scene Reveil : ouverture de 5%
        elseif(item.isScene) then
            deviceId=1612171344
            endpointId=1612171343
            pOuverture=5
            voletName=domoticz.helpers.DEVICE_VOLET_NOUS
        end
        
        
        -- Callback
        if (item.isHTTPResponse) then
            local response = item
            domoticz.log('Response HTTP : ' .. response.statusCode .. " - " .. response.statusText)
        -- Commande
        else
            domoticz.log("[".. voletName .."] set Position=" .. pOuverture .. "%")
                
            domoticz.openURL({
                    url = 'http://'..host_tydom_bridge..'/device/'..deviceId..'/endpoints/'..endpointId,
                    method = 'PUT',
                    header = { ['Content-Type'] = 'application/json' },
                    postData = { ['name'] = 'position', ['value'] = pOuverture },
                    callback = 'Tydom_volets_setPosition'
                })
        end   

    end       
}