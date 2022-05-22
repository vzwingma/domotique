return
{
    on =
    {
        scenes = { 'Soiree' }
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

        -- Activation de la lampe seulement  si présence
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
            -- (au maximum à la valeur level - si plus petit, on laisse au plus petit)
            -- fermeture individuelle pour ne pas réouvrir les volets (surtout de bébé)
            domoticz.log("[" .. domoticz.data.uuid .. "] Fermeture des volets Salon et Chambre au maximum à : " .. levelVoletsSoir .. "%", domoticz.LOG_INFO)
            setVoletsLevelToMinValue(domoticz.helpers.GROUPE_VOLETS_SALON, levelVoletsSoir)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_BEBE, levelVoletsSoir)
            setVoletsLevelToMinValue(domoticz.helpers.DEVICE_VOLET_NOUS, levelVoletsSoir)
        end
        
        -- Mode soirée, activation suivant le mode domicile.
        domoticz.data.uuid = domoticz.helpers.uuid()
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = item.name

        -- Récupération des paramètres et activation suivant le mode de domicile
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)

        activationLampeSalon(presenceDomicile)
        activationVolets(presenceDomicile, modeDomicile)
    end       
}