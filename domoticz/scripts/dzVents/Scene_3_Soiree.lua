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
        -- Fermeture du groupe de volets suivant le mode Domicile
        domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOff()
        
        -- Activation de la lampe seulement si mode par défaut ou Eté
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        if(modeDomicile == '' or modeDomicile == '_ete') then
            domoticz.devices(domoticz.helpers.DEVICE_LAMPE_SALON).setLevel(50)
        end
        
        -- Maj Level Salons pour relever suivant le paramétrage 
        local levelVoletsSalon = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
        domoticz.devices(domoticz.helpers.DEVICE_VOLET_SALON_G).setLevel(levelVoletsSalon)
        domoticz.devices(domoticz.helpers.DEVICE_VOLET_SALON_D).setLevel(levelVoletsSalon)
    end       
}