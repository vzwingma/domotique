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
        
        -- Met à jour le niveau du volet, ssi il est plus petit que la valeur existante
        function setVoletsLevelToMinValue(deviceName, levelVoletsSoir)
            local existingLevel = domoticz.devices(domoticz.helpers.deviceName).level
            local levelToSet = 0 
            if(levelVoletsSoir < existingLevel) then
                levelToSet = levelVoletsSoir
            else
                levelToSet = existingLevel
            end
            domoticz.devices(deviceName).setLevel(levelToSet)
        end
        
        -- Activation de la lampe seulement si mode par défaut ou Eté
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        if(modeDomicile == '' or modeDomicile == '_ete') then
            domoticz.devices(domoticz.helpers.DEVICE_LAMPE_SALON).setLevel(50)
        end
        
        -- Maj Level Salons pour relever suivant le paramétrage 
        if( modeDomicile == '_ete') then
            local levelVoletsSoir = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_SALON_G, levelVoletsSoir)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_SALON_D, levelVoletsSoir)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_NOUS, levelVoletsSoir)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_BEBE, 0)
        else 
            -- Fermeture du groupe de volets Salon &  Chambres
            domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOff()
        end


    end       
}