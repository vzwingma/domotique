return
{
    on =
    {
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Volets] "
    },
    execute = function(domoticz, item)
        
        local deviceId = nil
        local endpointId = nil
        local pOuverture = 0
        local voletName = 'UKN'
        
        -- Commande de volets

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
        
        domoticz.log("[".. voletName .."] set Position=" .. pOuverture .. "%")

        -- Appel du bridge Tydom
        local postData = { ['name'] = 'position', ['value'] = pOuverture }
        domoticz.helpers.callTydomBridgePUT('/device/'..deviceId..'/endpoints/'..endpointId,postData, nil, domoticz)

    end       
}