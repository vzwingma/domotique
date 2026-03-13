return {
    on = {
        timer = { 'every hour' },
        devices = { 'MaJ Tydom Temperature' },
        httpResponses = { 'Tydom_heat_getTemp' }
    },
    data = {
        uuid       = { initial = "" },
        retryCount = { initial = 0  }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Temperature] "
    },
    execute = function(domoticz, item)

    -- ### Fonctions internes

        -- # Mise à jour de la temperature mesurée (issue de Tydom)
        function updateTemperatureMesuree(node)
            domoticz.log("[" .. domoticz.data.uuid .. "] Température mesurée =" .. node.value .. "°C", domoticz.LOG_INFO)
            domoticz.devices(domoticz.helpers.DEVICE_TYDOM_TEMPERATURE).updateTemperature(node.value)
        end
        
        
        -- # Réalignement du Thermostat par rapport à Tydom
        function updateThermostat(node)
            local commandeTyd = node.value
            if(commandeTyd == nil) then
                commandeTyd = 0
            end
            local commandeDz = domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).setPoint
            domoticz.log("[" .. domoticz.data.uuid .. "] Température [Commande Tydom = " .. commandeTyd .. "°C] [Commande Dz = ".. commandeDz .."°C]", domoticz.LOG_INFO)
                
            if(commandeDz ~= commandeTyd) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Réalignement du Tydom Thermostat sur Domoticz par rapport à la commande réelle [" .. commandeTyd .. "]", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(commandeTyd)
            end
        end
        
    -- ### Commandes
        
        -- ### Appel de Tydom bridge pour récupérer la température mesurée
        if (item.isTimer or item.isDevice) then
            domoticz.data.uuid = domoticz.helpers.uuid()
            domoticz.data.retryCount = 0
            domoticz.helpers.callTydomBridgeGET(domoticz.helpers.getTydomHeatURI(domoticz), domoticz.data.uuid, 'Tydom_heat_getTemp', domoticz)
            
        -- ### Callback
        elseif (item.isHTTPResponse) then
            local MAX_RETRIES = 3
            if item.ok then
                -- Succès nominal : réinitialiser le compteur et traiter la réponse
                domoticz.data.retryCount = 0
                -- Update Mesure temperature
                local tempMesureeNode = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'temperature')
                updateTemperatureMesuree(tempMesureeNode)
                
                -- Update SetPoint Temperature
                local tempSetNode = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'setpoint')
                updateThermostat(tempSetNode)
            else
                -- Echec : retry borné (max 3 tentatives, même corrId pour la traçabilité)
                local errorClass = domoticz.helpers.httpErrorClass(item.statusCode)
                domoticz.data.retryCount = domoticz.data.retryCount + 1
                local attempt = domoticz.data.retryCount
                if attempt <= MAX_RETRIES then
                    domoticz.log("[" .. domoticz.data.uuid .. "] Echec GET Tydom Temperature (" .. errorClass .. " " .. tostring(item.statusCode) .. ") — tentative " .. attempt .. "/" .. MAX_RETRIES .. ", retry en cours...", domoticz.LOG_ERROR)
                    domoticz.helpers.callTydomBridgeGET(domoticz.helpers.getTydomHeatURI(domoticz), domoticz.data.uuid, 'Tydom_heat_getTemp', domoticz)
                else
                    domoticz.log("[" .. domoticz.data.uuid .. "] Echec GET Tydom Temperature (" .. errorClass .. " " .. tostring(item.statusCode) .. ") — " .. MAX_RETRIES .. " tentatives épuisées, abandon.", domoticz.LOG_ERROR)
                end
            end
        end
    end
}