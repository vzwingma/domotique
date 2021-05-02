return
{
    on =
    {
        devices = { 'Tydom Thermostat' },
        httpResponses = { 'Tydom_heat_setPoint' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Thermostat] "
    },
    execute = function(domoticz, item)
        -- Commande de thermostat
        if (item.isDevice) then        
            domoticz.log("set T=" .. item.state .. "°C")
            local host_tydom_bridge = domoticz.variables('tydom_bridge_host').value

            domoticz.openURL({
                    url = 'http://'..host_tydom_bridge..'/device/1612171197/endpoints/1612171197',
                    method = 'PUT',
                    header = { ['Content-Type'] = 'application/json' },
                    postData = { ['name'] = 'setpoint', ['value'] = item.state },
                    callback = 'Tydom_heat_setPoint'
                })
            
        -- Callback
        elseif (item.isHTTPResponse) then
            local response = item
            domoticz.log(response, domoticz.LOG_DEBUG)
            domoticz.log('Response HTTP : ' .. response.statusCode .. " - " .. response.statusText)
        -- Catch exception
        else
            domoticz.log('There was an error', domoticz.LOG_ERROR)
        end        
    end       
}