-- ## Scripts de commande des groupes de Lumières
-- Script déclenché pour chaque groupe de lumières : lance les niveaux et statuts des lumières constituant le groupe (ou le groupe de groupe)
return
{
    on =
    {
        devices = { '[Grp] Lumières Salon' },
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Groupe Lumières] "
    },
    -- Activation du groupe de lumières
    execute = function(domoticz, group)
    -- ### Fonctions internes ###
        -- Recherche des volets du groupe
        function getLumieresNameFromGroup(group)

            if(group.name == domoticz.helpers.GROUPE_LUMIERES_SALON) then
                domoticz.log("Activation toutes lumières salon : " .. group.state, domoticz.LOG_INFO)
                return { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_SALON , domoticz.helpers.DEVICE_LAMPE_CUISINE }
            else
                return {}
            end
        end
        -- Recheche du niveau de lumières suivant l'état du groupe 
        function getLevelFromGroupState(group)
            if(group.state == 'On') then
                -- Ouverture du groupe de lumières suivant la valeur du niveau
               return group.level
            else
               return 0
            end
        end


        -- Vérification de la valeur du groupe // à ses items
        function verifyGroupeFromItem(groupe, items, domoticz)
            domoticz.log("Vérification des lumières du groupe [" .. groupe .. "]", domoticz.LOG_DEBUG )
            local valeur = nil
            local sameLevel = false
            for _, pair in pairs(items) do
                domoticz.log(" > " .. pair .. ":" , domoticz.LOG_DEBUG )
                if( domoticz.devices(pair).level ~= nil) then
                   if(valeur == nil or valeur == domoticz.devices(pair).level ) then
                        sameLevel = true
                    elseif(valeur ~= domoticz.devices(pair).level) then
                        sameLevel = false
                    end
                    valeur = domoticz.devices(pair).level 
                end
                
            end
            -- Réalignement du groupe si les volets du groupe ont la même valeur et différentes de celle du groupe
            if(sameLevel == true and domoticz.devices(groupe).level ~= valeur) then
                domoticz.log("Réalignement des lumières du groupe [" .. groupe .. "] " .. domoticz.devices(groupe).level .. " > " .. valeur .. "%", domoticz.LOG_DEBUG) 
                domoticz.devices(groupe).setLevel(valeur)
            end
        end


    -- ### Lancement du scénario du Groupe ###
        local lumieresName = getLumieresNameFromGroup(group)
        local levelSet = getLevelFromGroupState(group)
        for _, lumiereName in pairs(lumieresName) do 
            domoticz.log("Allumage de la lumière " .. lumiereName .. " à " .. levelSet .. "%", domoticz.LOG_INFO)
            domoticz.devices(lumiereName).setLevel(levelSet)
        end
        -- Alignement groupe
       -- verifyGroupeFromItem(group.name, lumieresName, domoticz)
    end       
}