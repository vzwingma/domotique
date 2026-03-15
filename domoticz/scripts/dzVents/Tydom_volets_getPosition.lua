return {
    on = {
        timer = { 'every 30 minutes' },
        httpResponses = { 'Tydom_volets_getPosition' }
    },
    data = {
        -- Carte de retry par volet (JSON : { "Volet X": nbTentatives }).
        -- Réinitialisée à chaque nouveau cycle timer. Permet de borner les retries
        -- par volet indépendamment quand plusieurs appels sont en vol simultané.
        retryMap = { initial = '{}' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Refresh] "
    },
    execute = function(domoticz, item)
        local MAX_RETRIES = 3

    -- ### Commandes
        
        -- ### Appel de Tydom bridge pour récupérer la valeur de la position
        if (item.isTimer) then
            -- Réinitialiser la carte de retry pour ce nouveau cycle
            domoticz.data.retryMap = '{}'
            
            for _, kdeviceName in pairs(domoticz.helpers.DEVICES_TOUS_VOLETS) do 
                local uuid = domoticz.helpers.uuid()
                local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(kdeviceName, domoticz)
                domoticz.log("[" .. uuid .. "] Refresh position du volet " .. kdeviceName, domoticz.LOG_INFO) --.. " (" .. tydomIds.deviceId .. "/" .. tydomIds.endpointId .. ")")
                domoticz.helpers.callTydomBridgeGET('/device/' .. tydomIds.deviceId .. '/endpoints/' .. tydomIds.endpointId, uuid, 'Tydom_volets_getPosition', domoticz)
            end

        -- ### Callback
        elseif (item.isHTTPResponse) then
            local corrId = (item.headers and item.headers["X-CorrId"]) or "n/a"

            if item.ok then
                -- Succès nominal : traitement métier inchangé
                local positionTydom = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'position').value
                local validityPositionTydom = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'position').validity
                
                local voletName = domoticz.helpers.getDzItemFromTydomDeviceId(item.headers["X-Request-DeviceId"], item.headers["X-Request-EndpointId"], domoticz)
                local positionDz = domoticz.devices(voletName).level
                domoticz.log('[' .. corrId .. '] Volet ' .. voletName .. ' [Commande Tydom = ' .. positionTydom .. '%, (validite='.. validityPositionTydom ..')] [Commande Dz = '.. positionDz ..'%]', domoticz.LOG_INFO)
                
                if(positionDz > positionTydom + 1 or positionDz < positionTydom - 1 ) then
                    domoticz.log("[" .. corrId .. "] Réalignement du niveau de Volet sur Domoticz par rapport à la commande réelle [" .. positionTydom .. "]", domoticz.LOG_INFO)
                    domoticz.devices(voletName).setLevel(positionTydom)
                end
            else
                -- Echec : retry borné par volet (même corrId pour la traçabilité)
                local errorClass = domoticz.helpers.httpErrorClass(item.statusCode)

                -- Identification du volet (les headers peuvent être nil sur erreur réseau)
                local deviceId  = item.headers and item.headers["X-Request-DeviceId"]
                local endpointId = item.headers and item.headers["X-Request-EndpointId"]
                local voletName  = deviceId and domoticz.helpers.getDzItemFromTydomDeviceId(deviceId, endpointId, domoticz)

                if voletName == nil then
                    domoticz.log("[" .. corrId .. "] Echec GET volet inconnu (" .. errorClass .. " " .. tostring(item.statusCode) .. ") — volet non identifiable (headers absents), abandon.", domoticz.LOG_ERROR)
                    return
                end

                -- Lecture et mise à jour du compteur de retry pour ce volet
                local retryMap   = domoticz.utils.fromJSON(domoticz.data.retryMap) or {}
                local attempt    = (retryMap[voletName] or 0) + 1

                if attempt <= MAX_RETRIES then
                    domoticz.log("[" .. corrId .. "] Echec GET volet " .. voletName .. " (" .. errorClass .. " " .. tostring(item.statusCode) .. ") — tentative " .. attempt .. "/" .. MAX_RETRIES .. ", retry en cours...", domoticz.LOG_ERROR)
                    retryMap[voletName]    = attempt
                    domoticz.data.retryMap = domoticz.utils.toJSON(retryMap)
                    local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(voletName, domoticz)
                    domoticz.helpers.callTydomBridgeGET('/device/' .. tydomIds.deviceId .. '/endpoints/' .. tydomIds.endpointId, corrId, 'Tydom_volets_getPosition', domoticz)
                else
                    domoticz.log("[" .. corrId .. "] Echec GET volet " .. voletName .. " (" .. errorClass .. " " .. tostring(item.statusCode) .. ") — " .. MAX_RETRIES .. " tentatives épuisées, abandon.", domoticz.LOG_ERROR)
                end
            end
        end
    end
}