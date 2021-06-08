return
{
    on =
    {
        groups = { '[Grp] Volets Salon', '[Grp] Tous Volets' },
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
                domoticz.log("Ouverture tous volets : " .. group.state)
                return { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D, domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS }
                
            elseif(group.name == domoticz.helpers.GROUPE_VOLETS_SALON) then
                domoticz.log("Ouverture Volets Salon " .. group.state)
                return { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }
            else
                return {}
            end
        end
        -- Recheche du niveau de volets suivant l'état du groupe et du modeDomicile
        function getLevelFromGroupState(group)
            local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
            if(group.state == 'On') then
                -- Ouverture du groupe de volets suivant le mode Domicile
               return domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value
            else
                -- Fermeture du groupe de volets suivant le mode Domicile
               return domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
            end
        end
    
    -- ### Lancement du scénario du Groupe ###
        local voletsName = getVoletsNameFromGroup(group)
        local level = getLevelFromGroupState(group)
        
        for i, voletName in ipairs(voletsName) do 
            domoticz.log("Ouverture du volet " .. voletName .. " à " .. level .. "%")
            domoticz.devices(voletName).setLevel(level)
        end
    
    end       
}