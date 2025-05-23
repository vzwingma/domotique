return {
    on = {
        timer = { 'at 13:45' },
    },
    data = {
        seuilBattery = { initial = 20 },
        seuilData = { initial = 10080 },
        devicesNoDataAllowed =  { initial = { 69, 70, 114, 117, 119, 125, 130 }},
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Supervision IoT devices] "
    },
    execute = function(domoticz, item)
        
        -- # Supervision de la batterie de l'IoT
        function supervisionBatteryLevel(device)
            -- Alerte si < 20%
            if(device.batteryLevel ~= nil and device.batteryLevel < domoticz.data.seuilBattery) then
                domoticz.log('[' .. domoticz.data.uuid .. '] Device [' .. device.name .. '] - Niveau de batterie : ' .. device.batteryLevel .. '%', domoticz.LOG_ERROR)
                domoticz.helpers.notify('Capteur [' .. device.name .. '] - Batterie : ' .. device.batteryLevel .. '%', domoticz.data.uuid, domoticz)
            else 
                domoticz.log('[' .. domoticz.data.uuid .. '] Device [' .. device.name .. '] - Niveau de batterie : ' .. device.batteryLevel .. '%', domoticz.LOG_DEBUG)
            end

        end
        
        -- # Supervision des datas : mise à jour aujourd'hui ? sauf pour les devices devicesNoDataAllowed
        function supervisionData(device)
            domoticz.data.devicesNoDataAllowed =  { 69, 70, 110, 114, 119, 125, 130 }

            local deviceToIgnore = domoticz.helpers.tabContainsItem(domoticz.data.devicesNoDataAllowed, device.id, domoticz)
            domoticz.log('[' .. domoticz.data.uuid .. '] Device [' .. device.id .. '/' .. device.name .. '] - Dernière mise à jour, il y a ' .. device.lastUpdate.minutesAgo .. ' mins', domoticz.INFO)
            if( device.lastUpdate.minutesAgo > domoticz.data.seuilData and deviceToIgnore == false ) then
               domoticz.helpers.notify('Capteur [' .. device.name .. '] - Aucune réception de données depuis ' .. device.lastUpdate.minutesAgo .. ' mins', domoticz.data.uuid, domoticz)
            end
            
        end
        domoticz.data.uuid = domoticz.helpers.uuid()
        -- Itération sur tous les devices
        domoticz.devices().forEach(function(device)

            if(device.lastUpdate ~= nil) then
               supervisionData(device) 
            end
            -- Filtre sur les équipements qui ont une batterie
            if (device.batteryLevel ~= nil) then
                supervisionBatteryLevel(device)
            end
        end)
    end
}