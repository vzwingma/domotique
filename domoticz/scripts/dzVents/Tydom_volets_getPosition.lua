return {
    on = {
        timer = { 'every 30 minutes' },
        httpResponses = { 'Tydom_volets_getPosition' }
    },
    logging = {
        level = domoticz.LOG_ERROR,
        marker = "[TYDOM Refresh] "
    },
    execute = function(domoticz, item)
    -- ### Commandes
        
        -- ### Appel de Tydom bridge pour récupérer la valeur de la position
        if (item.isTimer or item.isDevice) then
            
            for _, kdeviceName in pairs(domoticz.helpers.DEVICES_TOUS_VOLETS) do 
                local uuid = domoticz.helpers.uuid()
                local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(kdeviceName, domoticz)
                domoticz.log("[" .. uuid .. "] Refresh position du volet " .. kdeviceName, domoticz.LOG_DEBUG) --.. " (" .. tydomIds.deviceId .. "/" .. tydomIds.endpointId .. ")")
                domoticz.helpers.callTydomBridgeGET('/device/' .. tydomIds.deviceId .. '/endpoints/' .. tydomIds.endpointId, uuid, 'Tydom_volets_getPosition', domoticz)
            end

        -- ### Callback
        elseif (item.isHTTPResponse and item.ok) then
            local positionTydom = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'position').value
            local validityPositionTydom = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'position').validity
            
            local voletName = domoticz.helpers.getDzItemFromTydomDeviceId(item.headers["X-Request-DeviceId"], item.headers["X-Request-EndpointId"], domoticz)
            local uuidCallB = item.headers["X-CorrId"]
            local positionDz = domoticz.devices(voletName).level
            domoticz.log('[" .. uuid .. "] Volet ' .. voletName .. ' [Commande Tydom = ' .. positionTydom .. '%, (validite='.. validityPositionTydom ..')] [Commande Dz = '.. positionDz ..'%]', domoticz.LOG_INFO)
            
            if(positionDz > positionTydom + 1 or positionDz < positionTydom - 1 ) then
                domoticz.log("[" .. uuid .. "] Réalignement du niveau de Volet sur Domoticz par rapport à la commande réelle [" .. positionTydom .. "]", domoticz.LOG_INFO)
                domoticz.devices(voletName).setLevel(positionTydom)
            end
        end
    end
}