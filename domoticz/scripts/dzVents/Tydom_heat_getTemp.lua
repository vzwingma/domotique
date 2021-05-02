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
            local host_tydom_bridge = domoticz.variables('tydom_bridge_host').value

            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'/device/1612171197/endpoints/1612171197',
                method = 'GET',
                header = { ['Content-Type'] = 'application/json' },
                callback = 'Tydom_heat_getTemp'
            })
        -- Callback
        elseif (item.isHTTPResponse) then
            if (item.ok) then -- statusCode == 2xx
                domoticz.log(item.json, domoticz.LOG_DEBUG)
                
                local currentTempData = item.json.data
                for i, node in pairs(item.json.data) do
                    if(node.name == 'temperature') then
                        domoticz.log('Température Tydom =' .. node.value)
                        domoticz.devices('Tydom Chauffage').updateTemperature(node.value)
                    end
                end

                
            end
        end
    end
}