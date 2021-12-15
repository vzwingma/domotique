return
{
    on =
    {
        devices = { 'Tydom Thermostat' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Thermostat] "
    },
    execute = function(domoticz, item)
        -- Commande de thermostat
        domoticz.data.uuid = domoticz.helpers.uuid()
        local putData
        if(item.state == "0.00") then
            domoticz.log("[" .. domoticz.data.uuid .. "] Réglage du thermostat à Hors Gel", domoticz.LOG_INFO)
            putData = {{ ['name'] = 'setpoint', ['value'] = null }, { ['name'] = 'antifrostOn', ['value'] = true }}
        else
            domoticz.log("[" .. domoticz.data.uuid .. "] Réglage du thermostat à T=" .. item.state .. "°C", domoticz.LOG_INFO)
            putData = { ['name'] = 'setpoint', ['value'] = item.state }
            
        end
        domoticz.helpers.callTydomBridgePUT('/device/1612171197/endpoints/1612171197', putData, domoticz.data.uuid, nil, domoticz)
    end       
}