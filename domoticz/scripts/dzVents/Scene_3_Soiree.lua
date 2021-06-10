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
            
            -- Maj Level Salons pour relever suivant le paramétrage 
            local levelVoletsSalon = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_SALON_G).setLevel(levelVoletsSalon)
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_SALON_D).setLevel(levelVoletsSalon)
        else 
            -- Fermeture du groupe de volets Salon 
            domoticz.groups(domoticz.helpers.GROUPE_VOLETS_SALON).switchOff()
        end

        -- Fermeture du groupe de volets Chambres quelque soit le mode Domicile
        domoticz.groups(domoticz.helpers.GROUPE_VOLETS_CHAMBRES).switchOff()

    end       
}