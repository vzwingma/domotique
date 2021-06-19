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
            domoticz.devices(deviceName).setLevel(math.min(domoticz.devices(domoticz.helpers.deviceName).level, levelVoletsSoir))
        end

        -- Activation de la lampe seulement si mode par défaut ou Eté
        function activationLampeSalon()
            local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
            if(modeDomicile == '' or modeDomicile == '_ete') then
                domoticz.log("Allumage de la lampe du salon")
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_SALON).setLevel(50)
            else
                domoticz.log('Personne à la maison, pas d\'allumage des lampes')
            end
        end
    
        -- Maj Level Salon & Chambre suivant le paramétrage         
        function activationVolets()

            local levelVoletsSoir = nil
            if( modeDomicile == '_ete') then
                levelVoletsSoir = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
            else 
                levelVoletsSoir = 0
            end
    
            -- Fermeture du groupe de volets Salon &  Chambres
            domoticz.log("Fermeture des volets Salon et Chambre : " .. levelVoletsSoir .. "%")
            setVoletsLevelToMinValue(domoticz.helpers.GROUPE_VOLETS_SALON, levelVoletsSoir)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_NOUS, levelVoletsSoir)
            
            domoticz.log("Fermeture du volet "..domoticz.helpers.DEVICE_VOLET_BEBE .. " : 0 %")
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_BEBE, 0)
        end
        
        activationLampeSalon()
        activationVolets()
    end       
}