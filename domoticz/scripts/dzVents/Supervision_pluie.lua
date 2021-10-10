return {
    on = {
        timer = { 'every 30 minutes' }
    },
    data = {
        previousRainRate = { initial = 0 }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Supervision Pluie] "
    },
    execute = function(domoticz, item)
        
        -- # Supervision du niveau de la pluie
        function supervisionPluie(devicePluie)
            domoticz.log(devicePluie.name .. ' ' .. devicePluie.rainRate .. ' mm.  [ ' .. devicePluie.rain .. ' mm/j ]')
            -- Alerte si > 0.5
            if(devicePluie.rainRate ~= nil and devicePluie.rainRate > 0.5 and devicePluie.rainRate ~= domoticz.data.previousRainRate) then
                domoticz.log('Il pleut ' .. devicePluie.rainRate .. 'mm', domoticz.LOG_ERROR)
                domoticz.data.previousRainRate = devicePluie.rainRate
                domoticz.helpers.notify('Alerte pluie : ' .. devicePluie.rainRate .. 'mm', domoticz)
            end

        end

        -- Supervision de la pluie        
        supervisionPluie(domoticz.devices('Precipitation'))
    end
}