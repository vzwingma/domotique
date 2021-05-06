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
    execute = function(domoticz, group)
        
        voletsName = nil
        -- Activation du groupe de volets
        if(group.name == domoticz.helpers.GROUPE_TOUS_VOLETS) then
            domoticz.log("Ouverture tous volets : " .. group.state)
            voletsName = { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D, domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS }
            
        elseif(group.name == domoticz.helpers.GROUPE_VOLETS_SALON) then
            domoticz.log("Ouverture Volets Salon " .. group.state)
            voletsName = { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }

        end
        -- set du pourcentage suivant l'état du groupe
        local level = 50
        if(group.state == 'On') then
           level = 100 
        else
            level = 0
        end
    
        for i, voletName in ipairs(voletsName) do 
            domoticz.log("Ouverture du volet "..voletName .. " : " .. level .. "%")
            domoticz.devices(voletName).setLevel(level)
        end
    
    end       
}