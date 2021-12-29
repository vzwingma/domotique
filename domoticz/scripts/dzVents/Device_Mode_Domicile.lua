return {
    on = {
        devices = { 'Mode' },
    },
    data = {
        previousMode = { initial = '' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Mode Domicile] "
    },
    execute = function(domoticz, device)

        -- Activation si passage en mode "Normal"
        local modeDomicile = device.levelName
        
        -- Notification lors du changement de mode, si changement
        if(modeDomicile ~= domoticz.data.previousMode) then
            domoticz.helpers.notify('Changement Mode : ' .. device.levelName, domoticz.helpers.uuid(), domoticz)
            
            if(modeDomicile == 'Normal') then
               domoticz.log("Réactivation du scénario : " .. domoticz.globalData.scenePhase) 
            end
            
        end
    end
}