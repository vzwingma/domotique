-- ## Scripts de commande des groupes de volets
-- Script déclenché pour chaque groupe de volet : lance les niveaux et statuts des volets constituant le groupe (ou le groupe de groupe)
return
{
    on =
    {
        devices = { '[Grp] Volets Salon', '[Grp] Tous Volets', '[Grp] Volets Chambres' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Groupe Volets] "
    },
    -- Activation du groupe de volets
    execute = function(domoticz, group)
    -- ### Fonctions internes ###
        -- Recherche des volets du groupe
        function getVoletsNameFromGroup(groupName)
            domoticz.log("[" .. domoticz.data.uuid .. "] Recherche des volets du groupe " .. groupName, domoticz.LOG_DEBUG)
            if(groupName == domoticz.helpers.GROUPE_TOUS_VOLETS) then
                return { domoticz.helpers.DEVICE_VOLET_NOUS, domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }
            
            elseif(groupName == domoticz.helpers.GROUPE_VOLETS_CHAMBRES) then
                return { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS }
                
            elseif(groupName == domoticz.helpers.GROUPE_VOLETS_SALON) then
                return { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }
            else
                return {}
            end
        end

        -- Alignement des groupes de volets
        -- Vérification de la valeur du groupe // à ses items (les autres groupes)
        function verifyGroupeFromItem(groupe, items, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Vérification des groupes du groupe [" .. groupe .. "]", domoticz.LOG_DEBUG )
            local valeur = nil
            local sameLevel = false
            for _, pair in pairs(items) do
                domoticz.log("[" .. domoticz.data.uuid .. "]  > " .. pair .. ":" .. domoticz.devices(pair).level, domoticz.LOG_DEBUG )
                if(valeur == nil or valeur == domoticz.devices(pair).level ) then
                    sameLevel = true
                elseif(valeur ~= domoticz.devices(pair).level) then
                    sameLevel = false
                end
                valeur = domoticz.devices(pair).level 
            end
            -- Réalignement du groupe si les volets du groupe ont la même valeur et différentes de celle du groupe
            if(sameLevel == true and domoticz.devices(groupe).level ~= valeur) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Réalignement des groupes du groupe [" .. groupe .. "] " .. domoticz.devices(groupe).level .. " > " .. valeur .. "%", domoticz.LOG_INFO) 
                domoticz.devices(groupe).setLevel(valeur).silent()
            end
        end


    -- ### Lancement du scénario du Groupe ###
        domoticz.data.uuid = domoticz.helpers.uuid()
        local voletsName = getVoletsNameFromGroup(group.name)
        domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture " .. group.name .. " : " .. group.state, domoticz.LOG_INFO)
        local levelSet = domoticz.helpers.getLevelFromState(group)
        for i, voletName in ipairs(voletsName) do 
            domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture du volet " .. voletName .. " à " .. levelSet .. "%", domoticz.LOG_INFO)
            domoticz.devices(voletName).setLevel(levelSet)
        end
        -- Alignement du groupe de groupe
        verifyGroupeFromItem(domoticz.helpers.GROUPE_TOUS_VOLETS, { domoticz.helpers.GROUPE_VOLETS_CHAMBRES, domoticz.helpers.GROUPE_VOLETS_SALON } , domoticz)
    end       
}