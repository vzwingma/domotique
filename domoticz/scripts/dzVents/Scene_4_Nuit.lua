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

        -- Fermeture du groupe de volets  (quel que soit le mode Domicile)
        domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOff()
        
        -- Thermostat pour la nuit, suivant le mode Domicile
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        local tempNuit = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_SOIR .. modeDomicile).value
        domoticz.log("Activation pour la nuit. Temp=[" .. tempNuit .. "]")
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempNuit)
    end       
}