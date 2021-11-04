return {
    on = {
        timer = { 'every 30 minutes' }
    },
    data = {
        previousRainRate = { initial = 0 },
        previousRainState = { initial = 'Off' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Supervision Pluie] "
    },
    execute = function(domoticz, item)
        
        -- # Supervision du niveau de la pluie
        function supervisionPluie(devicePluie, deviceIlPleut, domoticz)
            domoticz.log(devicePluie.name .. ' ' .. devicePluie.rainRate .. ' mm.  [ ' .. devicePluie.rain .. ' mm/j ] : ' .. deviceIlPleut.state)
            -- Alerte si > 0.5
            if(devicePluie.rainRate ~= nil and devicePluie.rainRate > 0.2 and devicePluie.rainRate ~= domoticz.data.previousRainRate) then
                domoticz.log('Il pleut ' .. devicePluie.rainRate .. 'mm', domoticz.LOG_INFO)
                domoticz.data.previousRainRate = devicePluie.rainRate
                domoticz.helpers.notify('Alerte pluie : ' .. devicePluie.rainRate .. 'mm', domoticz)
            end
            if(deviceIlPleut.state == 'On' and deviceIlPleut.state ~= domoticz.data.previousRainState) then
                domoticz.log('Il pleut !', domoticz.LOG_INFO)
                domoticz.helpers.notify('Alerte pluie', domoticz)
                domoticz.data.previousRainState = deviceIlPleut.state
            end
        end

        -- Supervision de la pluie        
        supervisionPluie(domoticz.devices('Precipitation'), domoticz.devices('Il pleut ?'), domoticz)
    end
}