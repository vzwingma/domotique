return {
    on = {
        httpResponses = { 'Tydom_heat_setPoint_callback' }
    },
    execute = function(domoticz, response)
        domoticz.log(response, domoticz.LOG_DEBUG)
        if (response.isHTTPResponse) then
                domoticz.log('Response HTTP : ' .. response.statusCode .. " - " .. response.statusText)
        else
            domoticz.log('There was an error', domoticz.LOG_ERROR)
        end
    end
}