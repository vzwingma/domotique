return {
    on = {
        timer = { 'every hour' },
        devices = { 'MaJ Tydom Temperatures' },
        httpResponses = { 'Tydom_heat_getTemp' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Temperature] "
    },
    execute = function(domoticz, item)

    -- ### Fonctions internes

        -- # Mise à jour de la temperature mesurée (issue de Tydom)
        function updateTemperatureMesuree(node)
            domoticz.log('Température mesurée =' .. node.value .. '°C')
            domoticz.devices(domoticz.helpers.DEVICE_TYDOM_TEMPERATURE).updateTemperature(node.value)
        end
        
        
        -- # Réalignement du Thermostat par rapport à Tydom
        function updateThermostat(node)
            local commandeTyd = node.value
            if(commandeTyd == null) then
                commandeTyd = 0
            end
            local commandeDz = domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).setPoint
            domoticz.log('Température [Commande Tydom = ' .. commandeTyd .. '°C] [Commande Dz = '.. commandeDz ..'°C]')
                
            if(commandeDz ~= commandeTyd) then
                domoticz.log("Réalignement du Tydom Thermostat sur Domoticz par rapport à la commande réelle [" .. commandeTyd .. "]", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(commandeTyd)
            end
        end
        
    -- ### Commandes
        
        -- ### Appel de Tydom bridge pour récupérer la température mesurée
        if (item.isTimer or item.isDevice) then
            domoticz.helpers.callTydomBridgeGET('/device/1612171197/endpoints/1612171197', 'Tydom_heat_getTemp', domoticz)
            
        -- ### Callback
        elseif (item.isHTTPResponse and item.ok) then
            -- Update Mesure temperature
            local tempMesureeNode = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'temperature')
            updateTemperatureMesuree(tempMesureeNode)
            
            -- Update SetPoint Temperature
            local tempSetNode = domoticz.helpers.getNodeFromJSonTreeByName(item.json.data, 'setpoint')
            updateThermostat(tempSetNode)
            
        end
    end
}