return
{
    on =
    {
        scenes = { 'Nuit' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Nuit] "
    },
    execute = function(domoticz, scene)

        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        domoticz.data.uuid = domoticz.helpers.uuid()
        
        -- Thermostat pour la nuit, suivant le mode Domicile
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        local tempNuit = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_SOIR .. presenceDomicile).value
        
        domoticz.log("[" .. domoticz.data.uuid .. "] Activation pour la nuit. Temp=[" .. tempNuit .. "]", domoticz.LOG_INFO)
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempNuit)

        -- Extinction des lampes
        domoticz.emitEvent('Scenario Nuit', { data = false, uuid = domoticz.data.uuid }) -- event vers les devices lampes        
    end       
}