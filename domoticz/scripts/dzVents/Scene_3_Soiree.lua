return
{
    on =
    {
        scenes = { 'Soiree' },
        customEvents = { 'Presence Domicile' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Soiree] "
    },
    execute = function(domoticz, item)
        
        -- Met à jour le niveau du volet, ssi il est plus petit que la valeur existante
        function setVoletsLevelToMinValue(deviceName, levelVoletsSoir)
            local minLevelVoletsSoir = math.min(domoticz.devices(deviceName).level, levelVoletsSoir)
            domoticz.log("[" .. domoticz.data.uuid .. "] Fermeture du volet " .. deviceName .. " : " .. minLevelVoletsSoir .. "%", domoticz.LOG_INFO)
            domoticz.devices(deviceName).setLevel(minLevelVoletsSoir)
        end

        -- Activation de la lampe seulement  si présenc
        function activationLampeSalon(presenceDomicile)
            if(presenceDomicile == '') then
                local prcent_lumiere = domoticz.variables(domoticz.helpers.VAR_PRCENT_LUMIERE_SALON_SOIR).value
                domoticz.log("[" .. domoticz.data.uuid .. "] Allumage de la lampe du salon " .. prcent_lumiere .. "%", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_TV).setLevel(prcent_lumiere)
            else
                domoticz.log("[" .. domoticz.data.uuid .. "] Personne à la maison, pas d'allumage des lampes", domoticz.LOG_INFO)
            end
        end
    
        -- Maj Level Salon & Chambre suivant le paramétrage         
        function activationVolets(presenceDomicile, modeDomicile)

            local levelVoletsSoir = nil
            if( modeDomicile == '_ete') then
                levelVoletsSoir = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. modeDomicile).value
            else 
                levelVoletsSoir = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_SOIR .. presenceDomicile).value
            end
    
            -- Fermeture des groupes de volets Salon &  Chambres
            domoticz.log("[" .. domoticz.data.uuid .. "] Fermeture des volets Salon et Chambre : " .. levelVoletsSoir .. "%", domoticz.LOG_INFO)
            setVoletsLevelToMinValue(domoticz.helpers.GROUPE_TOUS_VOLETS, levelVoletsSoir)
        end
        
        -- Mode soirée, activation suivant le mode domicile.
        domoticz.data.uuid = domoticz.helpers.uuid()
        if(item.isScene) then
            -- Suivi de la phase du jour
            domoticz.globalData.scenePhase = item.name

            -- Récupération des paramètres et activation suivant le mode de domicile
            local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
            local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)

            activationLampeSalon(presenceDomicile)
            activationVolets(presenceDomicile, modeDomicile)
            
        -- + si la présence change dans une plage soirée < p < nuit, réactivation de la lampe
        elseif(item.isCustomEvent and item.data == "true" and domoticz.globalData.scenePhase == "Soiree") then
        
            activationLampeSalon('')
        
        end
    end       
}