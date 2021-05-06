return
{
    on =
    {
        devices = { 'Tydom Thermostat' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Thermostat] "
    },
    execute = function(domoticz, item)
        -- Commande de thermostat
        domoticz.log("Réglage du thermostat à T=" .. item.state .. "°C")
            
        local putData = { ['name'] = 'setpoint', ['value'] = item.state }
        domoticz.helpers.callTydomBridgePUT('/device/1612171197/endpoints/1612171197',putData, nil, domoticz)
    end       
}