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
        
        local tempNuit = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_SOIR).value
        domoticz.log("Activation pour la nuit. Temp=[" .. tempNuit .. "]")
        -- Fermeture du groupe de volets
        domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOn()
        -- Thermostat
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempNuit)
    end       
}