return
{
    on =
    {
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Volets] "
    },
    execute = function(domoticz, item)
        
        -- Commande de volets
        function updateVoletPosition(item, domoticz)
            -- Recherche du bon volet
            local voletName = item.name
            local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(item.name, domoticz)
            -- Pourcentage de Commande
            -- Réaligné par rapport à létat
            pOuverture = domoticz.helpers.getLevelFromState(item)
            domoticz.log("[" .. domoticz.data.uuid .. "] [".. voletName .."] set Position=" .. pOuverture .. "%", domoticz.LOG_INFO)
            -- Appel du bridge Tydom
            local postData = { ['name'] = 'position', ['value'] = pOuverture }
            domoticz.helpers.callTydomBridgePUT('/device/'..tydomIds.deviceId..'/endpoints/'..tydomIds.endpointId , postData, domoticz.data.uuid, nil, domoticz)

        end
        
        -- Alignement des groupes de volets
        function aligneGroupeVolet(item, domoticz)
            if(item == domoticz.helpers.DEVICE_VOLET_SALON_G or item == domoticz.helpers.DEVICE_VOLET_SALON_D) then
                verifyGroupeFromItem(domoticz.helpers.GROUPE_VOLETS_SALON, { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D} , domoticz)
            elseif(item == domoticz.helpers.DEVICE_VOLET_BEBE or item == domoticz.helpers.DEVICE_VOLET_NOUS) then
                verifyGroupeFromItem(domoticz.helpers.GROUPE_VOLETS_CHAMBRES, { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS} , domoticz)
            end
            -- 
            verifyGroupeFromItem(domoticz.helpers.GROUPE_TOUS_VOLETS, { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS, domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D} , domoticz)
        end

        -- Vérification de la valeur du groupe // à ses items
        function verifyGroupeFromItem(groupe, items, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Vérification du groupe " .. groupe, domoticz.LOG_DEBUG )
            local valeur = nil
            local sameLevel = false
            local level = 0
            for _, pair in pairs(items) do
                
                level = domoticz.helpers.getLevelFromState(domoticz.devices(pair))
                domoticz.log("[" .. domoticz.data.uuid .. "]  > " .. pair .. " : " .. level .. "%", domoticz.LOG_DEBUG )
                if(valeur == nil) then
                    sameLevel = true
                else
                    sameLevel = sameLevel and (valeur == level)
                end
                valeur = level 
            end
            -- Réalignement du groupe si les volets du groupe ont la même valeur et différentes de celle du groupe
            local levelGroupe = domoticz.helpers.getLevelFromState(domoticz.devices(groupe))
            if(sameLevel == true and levelGroupe ~= valeur) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Réalignement des volets du groupe [" .. groupe .. "] " .. levelGroupe .. " > " .. valeur .. "%", domoticz.LOG_INFO) 
                domoticz.devices(groupe).setLevel(valeur).silent()
            end
        end
        
        domoticz.data.uuid = domoticz.helpers.uuid()
        
        -- Commande de position de volet
        updateVoletPosition(item, domoticz)
        -- Alignement groupe
        aligneGroupeVolet(item.name, domoticz)
        
    end       
}