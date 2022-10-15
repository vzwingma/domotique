return {
    on = {
        -- Evénement poussé par la session Freebox
        customEvents = { 'Freebox session' },
        httpResponses = { 'freebox_statut' },        
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Freebox Statuts] "
    },
    execute = function(domoticz, item)
        
        -- Recherche des équipements connectés
        function callFreeboxStatus(session_token, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "][" .. session_token .. "] Recherche des équipements connectés", domoticz.LOG_DEBUG)
            
            domoticz.helpers.callFreeboxGET('/connection', session_token, domoticz.data.uuid , 'freebox_statut', domoticz)
            
        end

        
        
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
        
        
    -- ## Call back après session
    if(item.isCustomEvent) then
        domoticz.data.uuid = item.json.uuid
        local session_token = item.json.data
        
        domoticz.log("[" .. domoticz.data.uuid .. "] Réception de l'événement [" .. item.customEvent .. "] : " .. session_token, domoticz.LOG_DEBUG)
        callFreeboxStatus(session_token, domoticz)
    -- ## Call back après get connection
    elseif(item.isHTTPResponse and  item.callback == 'freebox_statut') then 
            
        if(item.statusCode == 200) then
            domoticz.log("[" .. domoticz.data.uuid .. "] Connection callback : " .. item.statusCode .. " - Data :" .. item.json.result.state , domoticz.LOG_DEBUG)
            getFreeboxStatus(item.json.result.state, domoticz)
        else 
            domoticz.log("[" .. domoticz.data.uuid .. "] Erreur de connexion à la Freebox " .. item.statusCode .. " - " .. item.json.msg , domoticz.LOG_ERROR)
        end
    end    
end
}