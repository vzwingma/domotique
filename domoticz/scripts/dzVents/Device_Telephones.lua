return {
    on = {
        devices = { 'Equipements Personnels' }
    },
    data = {
        previousPresenceTels = { initial = true },
        compteurNbTelsAZero = { initial = 0 },
        seuilDecoAbsence = { initial = 5 },
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Equipements Personnels] "
    },
    execute = function(domoticz, item)
        
        -- Notification par SMS lors du changement de nombre de connexions
        function notifyConnectedDevices(presenceTels, uuid, domoticz)
            -- if(presenceTels ~= domoticz.data.previousPresenceTels) then
                domoticz.emitEvent('Presence Domicile', { data = presenceTels, uuid = uuid })
                domoticz.data.previousPresenceTels = presenceTels
            -- end
        end

        domoticz.data.uuid = domoticz.helpers.uuid()

        local nbTels = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).sensorValue
        local presenceTels = nbTels > 0
        domoticz.log("[" .. domoticz.data.uuid .. "] Nombre de téléphones connectés : " .. nbTels .. " - Présence : " .. tostring(presenceTels), domoticz.LOG_DEBUG)
        
        if(nbTels == 0) then
            -- Aucun tel : on incrémente un compteur pour éviter les faux positifs
            domoticz.data.compteurNbTelsAZero = domoticz.data.compteurNbTelsAZero + 1 
            if(domoticz.data.compteurNbTelsAZero >= domoticz.data.seuilDecoAbsence) then
                notifyConnectedDevices(presenceTels, domoticz.data.uuid, domoticz)  -- notifie pour le changement de domicile
            end
        else 
            domoticz.data.compteurNbTelsAZero = 0
            notifyConnectedDevices(presenceTels, domoticz.data.uuid, domoticz)  -- notifie pour le changement de domicile
        end
    end
}
