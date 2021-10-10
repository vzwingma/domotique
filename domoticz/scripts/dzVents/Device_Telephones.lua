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
                domoticz.helpers.notify('Présence : ' .. tostring(presenceTels), domoticz)
            end
        end

        -- Changement du mode de domicile suivant la Présence
        function updateDomicileMode(presenceTels, domoticz)
            
            local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
            local modeDomDevice = domoticz.devices(domoticz.helpers.DEVICE_MODE_DOMICILE)
            -- mode domicile = absent
            if((modeDomicile == '' or modeDomicile == '_ete' ) and presenceTels == false) then
                domoticz.log("0 équipements -> Passage en mode Absent")
                modeDomDevice.setLevel('Absents')
            elseif(modeDomicile == '_abs' and presenceTels == true) then
                domoticz.log("Au moins un équipement -> Retour au mode précédent (Présent/Eté) " .. modeDomDevice.lastLevel)
                modeDomDevice.setLevel(modeDomDevice.lastLevel)
            end
        end
        
        local nbTels = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).sensorValue
        local presenceTels = nbTels > 0
        -- domoticz.log("Nombre de téléphones connectés : " .. nbTels .. " - Présence : " .. tostring(presenceTels), domoticz.LOG_DEBUG)
        notifyConnectedDevices(presenceTels, domoticz)        
        updateDomicileMode(presenceTels, domoticz)
        
        domoticz.data.previousPresenceTels = presenceTels
        
    end
}
