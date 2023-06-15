return {
    on = {
        -- Evénement poussé par la session Freebox
        customEvents = { 'freebox_session' },
        httpResponses = { 'freebox_lan_statuts' },
    },
    data = {
        uuid = { initial = "" },
        session_token = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Freebox LAN Statuts] "
    },
    execute = function(domoticz, item)
        
        -- Statuts des interfaces connectées
        function getFreeboxLanStatuts(freeboxLanStates, domoticz)

            local mapStatutsTV = {}
            local mapStatutsDomotique = {}
            local mapStatutsNas = {}
            local mapStatutsWifi = {}
            
            
            for i, statut in ipairs(item.json.result) do 
                freeboxLanStatut(statut, mapStatutsTV, mapStatutsDomotique, mapStatutsNas, mapStatutsWifi)
            end
            
                                
            -- Mise à jour des infos dans Domoticz
            updateDomoticzStatut(mapStatutsDomotique, 2, domoticz.helpers.DEVICE_STATUT_DOMOTIQUE)
            updateDomoticzStatut(mapStatutsTV, 2, domoticz.helpers.DEVICE_STATUT_TV)
            updateDomoticzStatut(mapStatutsNas, 1, domoticz.helpers.DEVICE_STATUT_NAS)
            updatePersonnalConnectedDevices(mapStatutsWifi, domoticz)
            
            domoticz.emitEvent('freebox_endsession', { uuid = domoticz.data.uuid, sessionToken = domoticz.data.session_token })
        end
        
        
        -- #### Fonctions de lecture des statuts
        function freeboxLanStatut(statut, mapStatutsTV, mapStatutsDomotique, mapStatutsNas, mapStatutsWifi)
            domoticz.log("[" .. domoticz.data.uuid .. "]      device " .. statut.primary_name .. ", active=".. tostring(statut.active) .. ", reachable=".. tostring(statut.reachable), domoticz.LOG_DEBUG)
            
            if(statut.default_name == 'Freebox Player POP' or statut.default_name == 'LGwebOSTV' ) then
                mapStatutsTV[statut.primary_name]= statut.active
            elseif(statut.default_name == 'domatique' or statut.default_name == 'TYDOM-04B041' ) then
                mapStatutsDomotique[statut.primary_name]= statut.active
            elseif(statut.default_name == 'NAS-CS-VZ' ) then
                mapStatutsNas[statut.primary_name]= statut.active
            elseif(statut.host_type == 'smartphone' and true ~= mapStatutsWifi[statut.primary_name] ) then
                mapStatutsWifi[statut.primary_name]= statut.active
            end

        end 
        

        -- #### Fonctions de mise à jour des statuts dans DomoticZ en fonction des équipements UP
        function updateDomoticzStatut(mapStatutsDevices, nbExpectedUp, domoticzDeviceToUpdate)
            local nbEquipementsUp = 0
            local domoticzStatutLabel = ""
            -- Tri des noms des devices
            local tkeys = {}
            for k in pairs(mapStatutsDevices) do table.insert(tkeys, k) end
            table.sort(tkeys)
            
            for _, kdevice in pairs(tkeys) do 
                local statutDevice = mapStatutsDevices[kdevice]
                domoticzStatutLabel = domoticzStatutLabel .. "" .. kdevice .. "=" .. tostring(statutDevice) .. " "
                if(statutDevice) then
                    nbEquipementsUp = nbEquipementsUp + 1
                end
            end
            
            local alertLevel = domoticz.ALERTLEVEL_GREY
            if(nbEquipementsUp >= nbExpectedUp) then
               alertLevel = domoticz.ALERTLEVEL_GREEN
            elseif(nbEquipementsUp == 0) then
                alertLevel = domoticz.ALERTLEVEL_RED
            else
                alertLevel = domoticz.ALERTLEVEL_ORANGE
            end
            -- Mise à jour du statut WAN
            domoticz.log("[" .. domoticz.data.uuid .. "] " .. domoticzDeviceToUpdate .. " = " .. domoticzStatutLabel, domoticz.LOG_DEBUG)
            domoticz.devices(domoticzDeviceToUpdate).updateAlertSensor(alertLevel, domoticzStatutLabel)
        end
        
        
        -- Mise à jour du statut du nombre de devices connectés
        function updatePersonnalConnectedDevices(mapStatutsWifi, domoticz)
            local nbPersonnalDevicesUp = 0
            
            local personnalDevicesTab = domoticz.utils.stringSplit(domoticz.variables(domoticz.helpers.VAR_LIVEBOX_DEVICES).value, ",")
            for i, personnalDevice in ipairs(personnalDevicesTab) do 
                if(mapStatutsWifi[personnalDevice]) then
                    domoticz.log("[" .. domoticz.data.uuid .. "] Wifi > tel [" .. personnalDevice .. "] connecté", domoticz.LOG_DEBUG)
                    nbPersonnalDevicesUp = nbPersonnalDevicesUp + 1
                end
            end
            domoticz.log("[" .. domoticz.data.uuid .. "] Wifi = " .. nbPersonnalDevicesUp .. " tels connectés", domoticz.LOG_DEBUG)
            if( nbPersonnalDevicesUp == 0 or nbPersonnalDevicesUp ~= domoticz.data.previousNbPersonnalDevicesUp ) then
                domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).updateCustomSensor(nbPersonnalDevicesUp)
                domoticz.data.previousNbPersonnalDevicesUp = nbPersonnalDevicesUp
            end
        end
        
        
        
    -- ## Call back après session
    if(item.isCustomEvent) then
        domoticz.data.uuid = item.json.uuid
        local session_token = item.json.data
        domoticz.data.session_token = session_token
        domoticz.log("[" .. domoticz.data.uuid .. "] Réception de l'événement [" .. item.customEvent .. "] : " .. session_token, domoticz.LOG_DEBUG)
        domoticz.helpers.callFreeboxGET('/lan/browser/pub', session_token, domoticz.data.uuid , 'freebox_lan_statuts', domoticz)
    -- ## Call back après get connection
    elseif(item.isHTTPResponse and  item.callback == 'freebox_lan_statuts') then 
            
        if(item.statusCode == 200) then
            domoticz.log("[" .. domoticz.data.uuid .. "] LAN callback : " .. item.statusCode .. " - Data :" .. tostring(item.json.success) , domoticz.LOG_DEBUG)
            getFreeboxLanStatuts(item.json.result, domoticz)
        else 
            domoticz.log("[" .. domoticz.data.uuid .. "] Erreur de connexion à la Freebox " .. item.statusCode .. " - " .. item.json.msg , domoticz.LOG_ERROR)
        end
    end    
end
}