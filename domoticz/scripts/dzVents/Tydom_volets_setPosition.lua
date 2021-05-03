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

        local deviceId = nil
        local endpointId = nil
        local pOuverture = 100
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
            
            -- Pourcentage de Commande
            if(item.state == 'Open') then
                pOuverture = 100
            elseif(item.state == 'Closed') then
                pOuverture = 0
            end
        
        -- Scene Reveil : ouverture de 5%
        elseif(item.isScene) then
            deviceId=1612171344
            endpointId=1612171343
            pOuverture=5
            voletName=domoticz.helpers.DEVICE_VOLET_NOUS
        end
            
        domoticz.log("[".. voletName .."] set Position=" .. pOuverture .. "%")
            
        domoticz.openURL({
            url = 'http://'..host_tydom_bridge..'/device/'..deviceId..'/endpoints/'..endpointId,
            method = 'PUT',
           header = { ['Content-Type'] = 'application/json' },
            postData = { ['name'] = 'position', ['value'] = pOuverture },
            callback = 'Tydom_volets_setPosition'
        })
    
    end       
}