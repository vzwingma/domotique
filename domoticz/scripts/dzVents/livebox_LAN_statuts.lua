-- ## Scripts de lecture des éléments issus du service Devices.Device.HGW de la Livebox

return {
    on = {
        shellCommandResponses = { 'livebox_LAN_statuts' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[ORANGE Livebox] "
    },
    execute = function(domoticz, item)
        
        -- #### Fonctions de lecture des statuts
        function liveboxStatut(statut)
            domoticz.log("Livebox " .. statut.Name .. " active=".. tostring(statut.Active))
            
            for i, child in ipairs(statut.Children) do 
                if(child.Name == "lan") then
                    
                    local mapStatutsTV = {}
                    local mapStatutsDomotique = {}
                    local mapStatutsWifi = {}
                    
                    for i, device in ipairs(child.Children) do 
                        liveboxInterface(device, mapStatutsTV, mapStatutsDomotique, mapStatutsWifi)
                    end
                    
                    -- Mise à jour des infos dans Domoticz
                    updateDomoticzStatut(mapStatutsDomotique, 2, domoticz.helpers.DEVICE_STATUT_DOMOTIQUE)
                    updateDomoticzStatut(mapStatutsTV, 2, domoticz.helpers.DEVICE_STATUT_TV)
                    updatePersonnalConnectedDevices(mapStatutsWifi, domoticz)
                end
            end
        end 
        
        -- #### Interfaces (ethx) ####
        function liveboxInterface(interface, mapStatutsTV, mapStatutsDomotique, mapStatutsWifi)
            domoticz.log(". Interface : " .. interface.Name .. " active=".. tostring(interface.Active), domoticz.LOG_DEBUG)

            if(interface.Name == "eth0" or interface.Name == "eth1") then
                mapStatutsDomotique = getLiveboxDevicesStatut(interface.Children, mapStatutsDomotique, "Domotique")
            elseif(interface.Name == "eth2" or interface.Name == "eth3") then
                 mapStatutsTV = getLiveboxDevicesStatut(interface.Children, mapStatutsTV, "TV")
            elseif(interface.Name == "eth4") then
                mapStatutsWifi = getLiveboxDevicesStatut(interface.Children, mapStatutsWifi, "WiFi")
            end
        end
        
        function getLiveboxDevicesStatut(devices, mapStatut, categorie)
            for i, device in ipairs(devices) do 
                domoticz.log("... " .. categorie .. " Device : " .. device.Name .. " active=".. tostring(device.Active), domoticz.LOG_DEBUG)
                mapStatut[device.Name]= device.Active
            end
            return mapStatut
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
            domoticz.log(domoticzDeviceToUpdate .. " = " .. domoticzStatutLabel, domoticz.LOG_INFO)
            domoticz.devices(domoticzDeviceToUpdate).updateAlertSensor(alertLevel, domoticzStatutLabel)
        end
        
        
        -- Mise à jour du statut du nombre de devices connectés
        function updatePersonnalConnectedDevices(mapStatutsWifi, domoticz)
            local nbPersonnalDevicesUp = 0
            
            local personnalDevicesTab = domoticz.utils.stringSplit(domoticz.variables(domoticz.helpers.VAR_LIVEBOX_DEVICES).value, ",")
            for i, personnalDevice in ipairs(personnalDevicesTab) do 
                if(mapStatutsWifi[personnalDevice]) then
                    nbPersonnalDevicesUp = nbPersonnalDevicesUp + 1
                end
            end
            domoticz.log(" = " .. nbPersonnalDevicesUp .. " devices connectés", domoticz.LOG_INFO)
            domoticz.devices(domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES).updateCustomSensor(nbPersonnalDevicesUp)
        end
        
        
        -- ## Déclenchement de la fonction globale
        if (item.ok) then -- statusCode == 2xx
            for i, statut in ipairs(item.json.status) do 
                liveboxStatut(statut)
            end
        else
            domoticz.log("Erreur lors de la recherche des appareils connectés", domoticz.LOG_ERROR)
        end
    
    end
}