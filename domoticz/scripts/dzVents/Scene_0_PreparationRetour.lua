return
{
    on =
    {
        scenes = { 'PreparationRetour' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Preparation Retour] "
    },
    execute = function(domoticz, scene)
        
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name

        -- Activation du groupe Matin sans le mode absence - permet de préparer le retour à la maison, à distance
        local modeDomicile = ''
        domoticz.log("Activation du mode [Retour à la maison]", domoticz.LOG_INFO)
        domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value)
        local tempRetour = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_MATIN .. modeDomicile).value
        domoticz.log("    Temp=[" .. tempRetour .. "]")
        -- Thermostat
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempRetour)
    end
}