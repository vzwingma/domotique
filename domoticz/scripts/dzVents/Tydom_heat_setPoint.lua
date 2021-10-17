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
       
        local putData
        if(item.state == "0.00") then
            domoticz.log("Réglage du thermostat à Hors Gel", domoticz.LOG_INFO)
            putData = {{ ['name'] = 'setpoint', ['value'] = null }, { ['name'] = 'antifrostOn', ['value'] = true }}
        else
            domoticz.log("Réglage du thermostat à T=" .. item.state .. "°C", domoticz.LOG_INFO)
            putData = { ['name'] = 'setpoint', ['value'] = item.state }
            
        end
        domoticz.helpers.callTydomBridgePUT('/device/1612171197/endpoints/1612171197',putData, nil, domoticz)
    end       
}