return {
    on = {
        devices = { 'Mode Domicile' }
    },
    data = {
        previousMode = { initial = '' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Mode domicile] "
    },
    execute = function(domoticz, item)
        -- Notification par SMS lors du changement de mode
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        if(modeDomicile ~= domoticz.data.previousMode) then
            domoticz.helpers.notify('Changement du mode Domicile : ' .. item.levelName, domoticz)
        end
        domoticz.data.previousMode = modeDomicile
    end
}

--