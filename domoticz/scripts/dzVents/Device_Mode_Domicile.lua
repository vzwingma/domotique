return {
    on = {
        devices = { 'Mode Domicile' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Mode domicile] "
    },
    execute = function(domoticz, item)
        -- Notification par SMS lors du changement de mode
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        domoticz.helpers.notify('Changement du mode Domicile : ' .. item.levelName, domoticz)
    end
}

--