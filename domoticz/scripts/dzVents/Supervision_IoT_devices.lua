return {
    on = {
        timer = { 'every day' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Supervision IoT devices] "
    },
    execute = function(domoticz, item)
        
        -- # Supervision de la batterie de l'IoT
        function supervisionBatteryLevel(device)
            -- Alerte si < 20%
            if(device.batteryLevel ~= nil and device.batteryLevel < 20) then
                domoticz.log('Device [' .. device.name .. '] - Niveau de batterie : ' .. device.batteryLevel .. '%', domoticz.LOG_ERROR)
                domoticz.helpers.notify('Capteur [' .. device.name .. '] - Batterie : ' .. device.batteryLevel .. '%', domoticz)
            end

        end
        
        domoticz.devices().forEach(function(device)
            -- Filtre sur les équipements qui ont une batterie
            if (device.batteryLevel ~= nil) then
                supervisionBatteryLevel(device)
            end
        end)
    end
}