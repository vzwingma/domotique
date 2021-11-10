return
{
    on =
    {
        scenes = { 'Soiree' },
        customEvents = { 'Presence Domicile' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Soiree] "
    },
    execute = function(domoticz, item)
        
        -- Met à jour le niveau du volet, ssi il est plus petit que la valeur existante
        function setVoletsLevelToMinValue(deviceName, levelVoletsSoir)
            local minLevelVoletsSoir = math.min(domoticz.devices(deviceName).level, levelVoletsSoir)
            domoticz.log("Fermeture du volet " .. deviceName .. " : " .. minLevelVoletsSoir .. "%", domoticz.LOG_INFO)
            domoticz.devices(deviceName).setLevel(minLevelVoletsSoir)
        end

        -- Activation de la lampe seulement si mode par défaut ou Eté, et si présence
        function activationLampeSalon(modeDomicile)
            if(modeDomicile == '' or modeDomicile == '_ete') then
                local prcent_lumiere = domoticz.variables(domoticz.helpers.VAR_PRCENT_LUMIERE_SALON_SOIR).value
                domoticz.log("Allumage de la lampe du salon " .. prcent_lumiere .. "%", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_TV).setLevel(prcent_lumiere)
            else
                domoticz.log('Personne à la maison, pas d\'allumage des lampes', domoticz.LOG_INFO)
            end
        end
    
        -- Maj Level Salon & Chambre suivant le paramétrage         
        function activationVolets(modeDomicile)

            local levelVoletsSoir = nil
            if( modeDomicile == '_ete') then
                levelVoletsSoir = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
            else 
                levelVoletsSoir = 0
            end
    
            -- Fermeture du groupe de volets Salon &  Chambres
            domoticz.log("Fermeture des volets Salon et Chambre : " .. levelVoletsSoir .. "%", domoticz.LOG_INFO)
            setVoletsLevelToMinValue(domoticz.helpers.GROUPE_VOLETS_SALON, levelVoletsSoir)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_NOUS, levelVoletsSoir)
            
            domoticz.log("Fermeture du volet "..domoticz.helpers.DEVICE_VOLET_BEBE .. " : 0 %", domoticz.LOG_INFO)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_BEBE, 0)
        end
        
        -- Mode soirée, activation suivant le mode domicile.
        if(item.isScene) then
            -- Suivi de la phase du jour
            domoticz.globalData.scenePhase = item.name
        
            local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
            activationLampeSalon(modeDomicile)
            activationVolets(modeDomicile)
            
        -- + si la présence change dans une plage soirée < p < nuit, réactivation de la lampe
        elseif(item.isCustomEvent and item.data == "true" and domoticz.globalData.scenePhase == "Soiree") then
        
            activationLampeSalon('')
        
        end
    end       
}