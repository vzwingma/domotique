-- ## Scripts de commande pour le matin en Semaine et en Week-end (mode spécial : présent en été)
return
{
    on =
    {
        scenes = { 'Journee Ete' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Journee] "
    },
    execute = function(domoticz, scene)
        
        domoticz.data.uuid = domoticz.helpers.uuid()

        -- Ouverture des volets pour le mode été
        function ouvertureVoletMatinEte(modeDomicile, domoticz)
            -- Ouverture du groupe Salon & Chambre Nous uniquement, les volets bébé s'ouvrent au min du mode et de l'ouverture courante
            local levelNous = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value
            domoticz.devices(domoticz.helpers.GROUPE_VOLETS_SALON).setLevel(levelNous)
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_NOUS).setLevel(levelNous)
            domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture à ".. levelNous .." % pour nous et le salon", domoticz.LOG_INFO)

            local paramOuvertureJourEte = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value
            local levelBebe = math.min(paramOuvertureJourEte, domoticz.helpers.getLevelFromState(domoticz.devices(domoticz.helpers.DEVICE_VOLET_BEBE)))
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_BEBE).setLevel(levelBebe)
            domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture à ".. levelBebe .." % pour bébé", domoticz.LOG_INFO)
        end    

        -- Activation du groupe (le niveau est suivant le mode Domicile) - spécifique pour les modes Ete & vacances
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)

        if(modeDomicile ~= '_ete') then
            domoticz.log("[" .. domoticz.data.uuid .. "] En mode normal ou vacances, le scénario 2b Journee Eté est ignoré", domoticz.LOG_INFO)
            return
        end

        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        -- Présence
        if(presenceDomicile == '') then
            domoticz.log("[" .. domoticz.data.uuid .. "] Activation matin pour le mode ['" .. presenceDomicile .. "'/'" .. modeDomicile .."']", domoticz.LOG_INFO)
            ouvertureVoletMatinEte(modeDomicile, domoticz)
        -- Absence
        elseif(presenceDomicile == '_abs') then
            -- en été absent. Pas d'ouverture
        end
    end       
}