return
{
    on =
    {
        scenes = { 'PreReveil' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene PreReveil] "
    },
    execute = function(domoticz, scene)
        
        local tempMatin = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_MATIN).value
        domoticz.log("Activation pour le matin. Temp=[" .. tempMatin .. "]")
        -- Thermostat
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempMatin)
    end       
}