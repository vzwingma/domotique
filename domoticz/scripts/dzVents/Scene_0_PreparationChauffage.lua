return
{
    on =
    {
        scenes = { 'PreparationChauffage' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene PreReveil] "
    },
    execute = function(domoticz, scene)
        -- Suivi de la phase du jour
        domoticz.data.uuid = domoticz.helpers.uuid()
        domoticz.emitEvent('Scene Phase', { idx = 0, data = scene.name, uuid = domoticz.data.uuid })

        -- Recherche de la température à appliquer suivant la présence
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        local tempMatin = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_MATIN .. presenceDomicile).value

        domoticz.log("[".. domoticz.helpers.uuid() .."] Activation pour le matin. Temp=[" .. tempMatin .. "]")
        -- Thermostat
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempMatin)
    end       
}