return {
    on = {
        timer = { 'every hour' },
        httpResponses = { 'Tydom_heat_getTemp' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Temperature] "
    },
    execute = function(domoticz, item)
        -- Appel de Tydom bridge pour récupérer la température mesurée
        if (item.isTimer) then
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value

            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'/device/1612171197/endpoints/1612171197',
                method = 'GET',
                header = { ['Content-Type'] = 'application/json' },
                callback = 'Tydom_heat_getTemp'
            })
        -- Callback
        elseif (item.isHTTPResponse) then
            if (item.ok) then -- statusCode == 2xx
             --   domoticz.log(item.json, domoticz.LOG_DEBUG)
                
                local currentTempData = item.json.data
                for i, node in pairs(item.json.data) do
                    if(node.name == 'temperature') then
                        domoticz.log('Température Mesure =' .. node.value)
                        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_TEMPERATURE).updateTemperature(node.value)
                    -- Réalignement du Thermostat par rapport à Tydom
                    elseif(node.name == 'setpoint') then
                        local commandeTyd = node.value
                        local commandeDz = domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).setPoint
                        domoticz.log('Température [Commande Tydom =' .. commandeTyd .. '] [Commande Dz = '.. commandeDz ..']')
                        if(commandeDz ~= commandeTyd) then
                            domoticz.log("Réalignement du Tydom Thermostat sur Domoticz par rapport à la commande réelle [" .. commandeTyd .. "]", domoticz.LOG_INFO)
                            domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(commandeTyd)
                        end
                    end                    
                end
            end
        end
    end
}