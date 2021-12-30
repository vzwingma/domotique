return
{
    on =
    {
        scenes = { 'PreparationChauffage' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene PreReveil] "
    },
    execute = function(domoticz, scene)
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        
        -- Recherche de la température à appliquer suivant la présence
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        local tempMatin = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_MATIN .. presenceDomicile).value

        domoticz.log("[".. domoticz.helpers.uuid() .."] Activation pour le matin. Temp=[" .. tempMatin .. "]")
        -- Thermostat
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempMatin)
    end       
}