return
{
    on =
    {
        devices = { 'Tydom Thermostat' },
        httpResponses = { 'Tydom_heat_setPoint' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Thermostat] "
    },
    execute = function(domoticz, item)
        -- Commande de thermostat
        if (item.isDevice) then        
            domoticz.log("set T=" .. item.state .. "°C")
            
            local putData = { ['name'] = 'setpoint', ['value'] = item.state }
            domoticz.helpers.callTydomBridgePUT('/device/1612171197/endpoints/1612171197',putData, 'Tydom_heat_setPoint', domoticz)
            
        -- Callback
        elseif (item.isHTTPResponse and item.ok) then
            domoticz.log('La commande de thermostat a bien été exécutée')
        end        
    end       
}