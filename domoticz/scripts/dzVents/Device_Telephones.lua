return {
    on = {
        devices = { 'Equipements Personnels' }
    },
    data = {
        previousPresenceTels = { initial = true }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Equipements Personnels] "
    },
    execute = function(domoticz, item)
        
        -- Notification par SMS lors du changement de nombre de connexions
        function notifyConnectedDevices(presenceTels, domoticz)
            if(presenceTels ~= domoticz.data.previousPresenceTels) then
                domoticz.emitEvent('Presence Domicile', presenceTels )
            end
        end

        local nbTels = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).sensorValue
        local presenceTels = nbTels > 0
        -- domoticz.log("Nombre de téléphones connectés : " .. nbTels .. " - Présence : " .. tostring(presenceTels), domoticz.LOG_DEBUG)
        notifyConnectedDevices(presenceTels, domoticz)  -- notifie pour le changement de domicile
        domoticz.data.previousPresenceTels = presenceTels
        
    end
}
