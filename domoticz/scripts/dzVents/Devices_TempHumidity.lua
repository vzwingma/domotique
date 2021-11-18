-- ## Scripts de mise à jour des devices virtuels Temp+Humidité à partir des valeurs des devices jumeaux numériques des capteurs Xioamo
-- Appelé pour chaque mise à jour des jumeaux numériques Température
return {
    on = {
        devices = { 'Température - Chambre Bébé', 'Température - Chambre Nous', 'Température - Salle de Bain' }
    },
    data = {
        previousPresenceTels = { initial = true },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TempHumidity] "
    },
    execute = function(domoticz, item)
        
        -- Notification par SMS lors du changement de nombre de connexions
        function updateTempHumidity(itemName, domoticz)
            local piece = string.sub(itemName, 16)
            domoticz.log("Mise à jour des valeurs de Température et d'Humidité de ".. piece, domoticz.LOG_DEBUG)
            local temp = domoticz.devices("Température - " .. piece).temperature
            local humidity = domoticz.devices("Humidité - " .. piece).humidity
            domoticz.log ("température=" .. temp .. "°C / humidité=" .. humidity .. "%", domoticz.LOG_DEBUG)
            domoticz.devices("TempératureHumidité - " .. piece).updateTempHum(temp, humidity)
        end

        updateTempHumidity(item.name, domoticz)
    end
}
