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
        local nbTels = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).sensorValue
        domoticz.log("Nombre de téléphones connectés : " .. nbTels, domoticz.LOG_DEBUG)
        local presenceTels = nbTels > 0
        if(presenceTels ~= domoticz.data.previousPresenceTels) then
            domoticz.helpers.notify('Présence : ' .. presenceTels, domoticz)
        end
        domoticz.data.previousPresenceTels = presenceTels
    end
}