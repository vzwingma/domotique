return
{
    on =
    {
        scenes = { 'Nuit' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Nuit] "
    },
    execute = function(domoticz, scene)

        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name

        -- Fermeture du groupe de volets  (quel que soit le mode Domicile)
        domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOff()
        -- Extinction des lampes
        domoticz.emitEvent('Scenario Nuit', "false" ) -- event vers les devices lampes
        
        -- Thermostat pour la nuit, suivant le mode Domicile
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        local tempNuit = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_SOIR .. modeDomicile).value
        
        domoticz.log("Activation pour la nuit. Temp=[" .. tempNuit .. "]", domoticz.LOG_INFO)
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempNuit)
    end       
}