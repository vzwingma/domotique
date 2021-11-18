return
{
    on =
    {
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Volets] "
    },
    execute = function(domoticz, item)
        
        local pOuverture = 0

        -- Commande de volets
        function updateVoletPosition(item, domoticz)
            -- Recherche du bon volet
            local voletName = item.name
            local tydomIds = domoticz.helpers.getTydomDeviceNumberFromDzItem(item.name, domoticz)
            -- Pourcentage de Commande
            -- Réaligné par rapport à létat
            if(item.state == 'Off' and item.level ~= 0) then
               item.setLevel(0)
            else
                pOuverture = item.level
            end
            
            domoticz.log("[".. voletName .."] set Position=" .. pOuverture .. "%", domoticz.LOG_INFO)
            
            -- Appel du bridge Tydom
            local postData = { ['name'] = 'position', ['value'] = pOuverture }
           domoticz.helpers.callTydomBridgePUT('/device/'..tydomIds.deviceId..'/endpoints/'..tydomIds.endpointId , postData, nil, domoticz)
        end
        
        -- Alignement des groupes de volets
        function aligneGroupeVolet(item, domoticz)
            if(item == domoticz.helpers.DEVICE_VOLET_SALON_G or item == domoticz.helpers.DEVICE_VOLET_SALON_D) then
                verifyGroupeFromItem(domoticz.helpers.GROUPE_VOLETS_SALON, { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D} , domoticz)
            elseif(item == domoticz.helpers.DEVICE_VOLET_BEBE or item == domoticz.helpers.DEVICE_VOLET_NOUS) then
                verifyGroupeFromItem(domoticz.helpers.GROUPE_VOLETS_CHAMBRES, { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS} , domoticz)
            elseif(item == domoticz.helpers.GROUPE_VOLETS_CHAMBRES or item == domoticz.helpers.GROUPE_VOLETS_SALON) then
                verifyGroupeFromItem(domoticz.helpers.GROUPE_TOUS_VOLETS, { domoticz.helpers.GROUPE_VOLETS_CHAMBRES, domoticz.helpers.GROUPE_VOLETS_SALON} , domoticz)
            end
        end

        -- Vérification de la valeur du groupe // à ses items
        function verifyGroupeFromItem(groupe, items, domoticz)
            domoticz.log("Vérification du groupe " .. groupe, domoticz.LOG_DEBUG )
            local valeur = nil
            local sameLevel = false
            for _, pair in pairs(items) do
                domoticz.log(" > " .. pair .. ":" .. domoticz.devices(pair).level)
                if(valeur == nil or valeur == domoticz.devices(pair).level ) then
                    sameLevel = true
                end
                valeur = domoticz.devices(pair).level 
            end
            -- Réalignement du groupe si les volets du groupe ont la même valeur et différentes de celle du groupe
            if(sameLevel and domoticz.devices(groupe).level ~= valeur) then
                domoticz.log("Réalignement des volets du groupe [" .. groupe .. "] " .. domoticz.devices(groupe).level .. " > " .. valeur .. "%", domoticz.LOG_INFO) 
                domoticz.devices(groupe).setLevel(valeur)
            end
        end
        
        -- Commande de position de volet
        updateVoletPosition(item, domoticz)
        -- Alignement groupe
        -- TODO : A valider
        -- aligneGroupeVolet(item.name, domoticz)
        
    end       
}