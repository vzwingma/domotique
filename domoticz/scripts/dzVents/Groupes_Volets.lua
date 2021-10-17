return
{
    on =
    {
        devices = { '[Grp] Volets Salon', '[Grp] Tous Volets', '[Grp] Volets Chambres' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Groupe Volets] "
    },
    -- Activation du groupe de volets
    execute = function(domoticz, group)
    -- ### Fonctions internes ###
        -- Recherche des volets du groupe
        function getVoletsNameFromGroup(group)
            
            if(group.name == domoticz.helpers.GROUPE_TOUS_VOLETS) then
                domoticz.log("Ouverture tous volets : " .. group.state, domoticz.LOG_INFO)
                return { domoticz.helpers.GROUPE_VOLETS_CHAMBRES, domoticz.helpers.GROUPE_VOLETS_SALON }
            
            elseif(group.name == domoticz.helpers.GROUPE_VOLETS_CHAMBRES) then
                domoticz.log("Ouverture Volets Chambres : " .. group.state, domoticz.LOG_INFO)
                return { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS }
                
            elseif(group.name == domoticz.helpers.GROUPE_VOLETS_SALON) then
                domoticz.log("Ouverture Volets Salon " .. group.state, domoticz.LOG_INFO)
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
    
    -- ### Lancement du scénario du Groupe ###
        local voletsName = getVoletsNameFromGroup(group)
        local levelSet = getLevelFromGroupState(group)
        for i, voletName in ipairs(voletsName) do 
            domoticz.log("Ouverture du volet " .. voletName .. " à " .. levelSet .. "%", domoticz.LOG_INFO)
            domoticz.devices(voletName).setLevel(levelSet)
        end
    
    end       
}