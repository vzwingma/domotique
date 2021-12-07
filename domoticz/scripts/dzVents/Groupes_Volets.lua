-- ## Scripts de commande des groupes de volets
-- Script déclenché pour chaque groupe de volet : lance les niveaux et statuts des volets constituant le groupe (ou le groupe de groupe)
return
{
    on =
    {
        devices = { '[Grp] Volets Salon', '[Grp] Tous Volets', '[Grp] Volets Chambres' },
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Groupe Volets] "
    },
    -- Activation du groupe de volets
    execute = function(domoticz, group)
    -- ### Fonctions internes ###
        -- Recherche des volets du groupe
        function getVoletsNameFromGroup(groupName)
            domoticz.log("Recherche des volets du groupe " .. groupName)
            if(groupName == domoticz.helpers.GROUPE_TOUS_VOLETS) then
                return { domoticz.helpers.GROUPE_VOLETS_CHAMBRES, domoticz.helpers.GROUPE_VOLETS_SALON }
            
            elseif(groupName == domoticz.helpers.GROUPE_VOLETS_CHAMBRES) then
                return { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS }
                
            elseif(groupName == domoticz.helpers.GROUPE_VOLETS_SALON) then
                return { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }
            else
                return {}
            end
        end
        -- Recheche du niveau de volets suivant l'état du groupe 
        function getLevelFromGroupState(group)
            if(group.state == 'On') then
                -- Ouverture du groupe de volets suivant la valeur du niveau
               return group.level
            else
               return 0
            end
        end

        -- Alignement des groupes de volets
        function aligneGroupeVolet(groupe, domoticz)
            domoticz.log("Vérification du groupe [" .. groupe .. "]", domoticz.LOG_DEBUG )
            if(groupe == domoticz.helpers.GROUPE_VOLETS_CHAMBRES or groupe == domoticz.helpers.GROUPE_VOLETS_SALON) then
                verifyGroupeFromItem(domoticz.helpers.GROUPE_TOUS_VOLETS, getVoletsNameFromGroup(domoticz.helpers.GROUPE_TOUS_VOLETS) , domoticz)
            end
        end

        -- Vérification de la valeur du groupe // à ses items
        function verifyGroupeFromItem(groupe, items, domoticz)
            domoticz.log("Vérification des groupes du groupe [" .. groupe .. "]", domoticz.LOG_DEBUG )
            local valeur = nil
            local sameLevel = false
            for _, pair in pairs(items) do
                domoticz.log(" > " .. pair .. ":" .. domoticz.devices(pair).level, domoticz.LOG_DEBUG )
                if(valeur == nil or valeur == domoticz.devices(pair).level ) then
                    sameLevel = true
                elseif(valeur ~= domoticz.devices(pair).level) then
                    sameLevel = false
                end
                valeur = domoticz.devices(pair).level 
            end
            -- Réalignement du groupe si les volets du groupe ont la même valeur et différentes de celle du groupe
            if(sameLevel == true and domoticz.devices(groupe).level ~= valeur) then
                domoticz.log("Réalignement des groupes du groupe [" .. groupe .. "] " .. domoticz.devices(groupe).level .. " > " .. valeur .. "%", domoticz.LOG_DEBUG) 
                domoticz.devices(groupe).setLevel(valeur)
            end
        end


    -- ### Lancement du scénario du Groupe ###
        local voletsName = getVoletsNameFromGroup(group.name)
        domoticz.log("Ouverture " .. group.name .. " : " .. group.state, domoticz.LOG_INFO)
        local levelSet = getLevelFromGroupState(group)
        for i, voletName in ipairs(voletsName) do 
            domoticz.log("Ouverture du volet " .. voletName .. " à " .. levelSet .. "%", domoticz.LOG_INFO)
            domoticz.devices(voletName).setLevel(levelSet)
        end
        -- Alignement groupe
        aligneGroupeVolet(group.name, domoticz)
    end       
}