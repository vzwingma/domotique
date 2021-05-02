return {
    on = {
        shellCommandResponses = { 'Tydom_heat_setPoint_callback' }
    },
    execute = function(domoticz, response)
        domoticz.log('Response ')
        domoticz.log(response)
        if response.ok then
            if (response.isJSON) then
                domoticz.log(response.json.some.value)
            end
        else
            domoticz.log('There was an error', domoticz.LOG_ERROR)
        end
    end
}