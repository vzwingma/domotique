return
{
    on =
    {
        devices = { 'Tydom Thermostat' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[TYDOM Thermostat] "
        },
    execute = function(domoticz, thermostat)
        
        domoticz.log("set T=" .. thermostat.state .. "°C")
    
        domoticz.openURL({
                url = 'http://192.168.19.1:9102/device/1612171197/endpoints/1612171197',
                method = 'PATCH',
                header = { ['Content-Type'] = 'application/json' },
                postData = { ['name'] = 'setpoint', ['value'] = '22.00' },
                callback = 'Tydom_heat_setPoint_callback'
            })
    end       
}