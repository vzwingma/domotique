return
{
    on =
    {
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' }
    },
    logging = {
        level = domoticz.LOG_INFO,
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
        local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(item.name, domoticz)
        -- Pourcentage de Commande
        -- Réaligné par rapport à létat
        if(item.state == 'Off' and item.level ~= 0) then
           item.setLevel(0)
        else
            pOuverture = item.level
        end
        
        domoticz.log("[".. voletName .."] set Position=" .. pOuverture .. "%", domoticz.LOG_INFO)
        
        -- Appel du bridge Tydom
        local postData = { ['name'] = 'position', ['value'] = pOuverture }
       domoticz.helpers.callTydomBridgePUT('/device/'..tydomIds.deviceId..'/endpoints/'..tydomIds.endpointId , postData, nil, domoticz)

    end       
}