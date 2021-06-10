return
{
    on =
    {
        scenes = { 'Soiree' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Soiree] "
    },
    execute = function(domoticz, scene)
        
        -- Activation de la lampe seulement si mode par défaut ou Eté
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        if(modeDomicile == '' or modeDomicile == '_ete') then
            domoticz.devices(domoticz.helpers.DEVICE_LAMPE_SALON).setLevel(50)
        end
        
        -- Maj Level Salons pour relever suivant le paramétrage 
        if( modeDomicile == '_ete') then
            local levelVoletsSalon = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_SALON_G).setLevel(levelVoletsSalon)
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_SALON_D).setLevel(levelVoletsSalon)
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_NOUS).setLevel(levelVoletsSalon)
        else 
            -- Fermeture du groupe de volets Salon &  Chambres
            domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOff()
        end


    end       
}