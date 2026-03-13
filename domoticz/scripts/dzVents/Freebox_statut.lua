return {
    on = {
        -- Evénement poussé par la session Freebox
        customEvents = { 'freebox_session' },
        httpResponses = { 'freebox_statut' },        
    },
    data = {
        uuid          = { initial = "" },
        session_token = { initial = "" },
        retryCount    = { initial = 0  }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Freebox Statut] "
    },
    execute = function(domoticz, item)
        
        -- Statut de la freebox
        -- @param : freeboxState : état de la freebox
        function getFreeboxStatus(freeboxState, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Etat de la Freebox : " .. tostring(freeboxState), domoticz.LOG_INFO)
           local alertLevel = domoticz.ALERTLEVEL_GREY
           if(freeboxState == "up") then
               alertLevel = domoticz.ALERTLEVEL_GREEN
            elseif(freeboxState == "down" ) then
                alertLevel = domoticz.ALERTLEVEL_RED
            else
                alertLevel = domoticz.ALERTLEVEL_GREY
            end
            -- Mise à jour du statut WAN
            domoticz.devices(domoticz.helpers.DEVICE_STATUT_FREEBOX).updateAlertSensor(alertLevel, "Box=" .. freeboxState)
        end
        
        local MAX_RETRIES = 3

    -- ## Call back après session
    if(item.isCustomEvent) then
        domoticz.data.uuid          = item.json.uuid
        domoticz.data.session_token = item.json.data
        domoticz.data.retryCount    = 0
        
        domoticz.log("[" .. domoticz.data.uuid .. "] Réception de l'événement [" .. item.customEvent .. "] : " .. domoticz.data.session_token, domoticz.LOG_DEBUG)
        domoticz.helpers.callFreeboxGET('/connection', domoticz.data.session_token, domoticz.data.uuid , 'freebox_statut', domoticz)

    -- ## Call back après get connection
    elseif(item.isHTTPResponse and  item.callback == 'freebox_statut') then 
            
        if(item.statusCode == 200) then
            domoticz.data.retryCount = 0
            domoticz.log("[" .. domoticz.data.uuid .. "] Connection callback : " .. item.statusCode .. " - Data :" .. item.json.result.state , domoticz.LOG_DEBUG)
            getFreeboxStatus(item.json.result.state, domoticz)
        else
            local errorClass = domoticz.helpers.httpErrorClass(item.statusCode)
            domoticz.data.retryCount = domoticz.data.retryCount + 1
            local attempt = domoticz.data.retryCount
            if attempt <= MAX_RETRIES then
                domoticz.log("[" .. domoticz.data.uuid .. "] Erreur GET Freebox statut (" .. errorClass .. " " .. tostring(item.statusCode) .. ") — tentative " .. attempt .. "/" .. MAX_RETRIES .. ", retry en cours...", domoticz.LOG_ERROR)
                domoticz.helpers.callFreeboxGET('/connection', domoticz.data.session_token, domoticz.data.uuid, 'freebox_statut', domoticz)
            else
                domoticz.log("[" .. domoticz.data.uuid .. "] Erreur GET Freebox statut (" .. errorClass .. " " .. tostring(item.statusCode) .. ") — " .. MAX_RETRIES .. " tentatives épuisées, abandon.", domoticz.LOG_ERROR)
            end
        end
    end    
end
}