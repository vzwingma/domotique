return {
    on = {
        devices = { 'Equipements Personnels' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Equipements Personnels] "
    },
    execute = function(domoticz, item)
        -- Notification par SMS lors du changement de nombre de connexions
        local nbTels = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).sensorValue
        domoticz.helpers.notify('Nb de téléphones connectés : ' .. nbTels, domoticz)
    end
}