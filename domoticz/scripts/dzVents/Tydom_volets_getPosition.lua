return {
    on = {
        timer = { 'every 30 minutes' },
        httpResponses = { 'Tydom_volets_getPosition' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Refresh] "
    },
    execute = function(domoticz, item)
    -- ### Commandes
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' }
        -- ### Appel de Tydom bridge pour récupérer la température mesurée
        if (item.isTimer or item.isDevice) then
            
            for _, kdeviceName in pairs(devices) do 
                local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(kdeviceName, domoticz)
                domoticz.log("Refresh position du volet " .. kdeviceName .. " (" .. tydomIds.deviceId .. "/" .. tydomIds.endpointId .. ")")
                domoticz.helpers.callTydomBridgeGET('/device/' .. tydomIds.deviceId .. '/endpoints/' .. tydomIds.endpointId, 'Tydom_volets_getPosition', domoticz)
            end

        -- ### Callback
        elseif (item.isHTTPResponse and item.ok) then
            local positionTydom = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'position').value
            local voletName = domoticz.helpers.getDzItemFromTydomDeviceId(item.headers["X-Request-DeviceId"], item.headers["X-Request-EndpointId"], domoticz)

            local positionDz = domoticz.devices(voletName).level
            domoticz.log('Volet ' .. voletName .. ' [Commande Tydom = ' .. positionTydom .. '%] [Commande Dz = '.. positionDz ..'%]')
                
            if(positionDz ~= positionTydom) then
                domoticz.log("Réalignement du niveau de Volet sur Domoticz par rapport à la commande réelle [" .. positionTydom .. "]", domoticz.LOG_INFO)
                domoticz.devices(voletName).setLevel(positionTydom)
            end
        end
    end
}