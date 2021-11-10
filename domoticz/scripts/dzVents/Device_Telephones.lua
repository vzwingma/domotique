return {
    on = {
        devices = { 'Equipements Personnels' }
    },
    data = {
        previousPresenceTels = { initial = true },
        compteurNbTelsAZero = { initial = 0 },
        seuilDecoAbsence = { initial = 3 },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Equipements Personnels] "
    },
    execute = function(domoticz, item)
        
        -- Notification par SMS lors du changement de nombre de connexions
        function notifyConnectedDevices(presenceTels, domoticz)
            if(presenceTels ~= domoticz.data.previousPresenceTels) then
                domoticz.emitEvent('Presence Domicile', presenceTels )
                domoticz.data.previousPresenceTels = presenceTels
            end
        end

        local nbTels = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).sensorValue
        local presenceTels = nbTels > 0
        domoticz.log("Nombre de téléphones connectés : " .. nbTels .. " - Présence : " .. tostring(presenceTels), domoticz.LOG_DEBUG)
        
        if(nbTels == 0) then
            -- Aucun tel : on incrémente un compteur pour éviter les faux positifs
            domoticz.data.compteurNbTelsAZero = domoticz.data.compteurNbTelsAZero + 1 
            if(domoticz.data.compteurNbTelsAZero >= domoticz.data.seuilDecoAbsence) then
                notifyConnectedDevices(presenceTels, domoticz)  -- notifie pour le changement de domicile
            end
        else 
            domoticz.data.compteurNbTelsAZero = 0
            notifyConnectedDevices(presenceTels, domoticz)  -- notifie pour le changement de domiciles
        end
    end
}
