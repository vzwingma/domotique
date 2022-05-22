-- ## Scripts de commande pour le matin en Semaine et en Week-end (mode spécial : absent en vacances)
return
{
    on =
    {
        scenes = { 'Matin Vacs' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Matin] "
    },
    execute = function(domoticz, scene)
        
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        domoticz.data.uuid = domoticz.helpers.uuid()

        -- Ouverture des volets pour le mode été
        function ouvertureVoletMatinVacs(modeDomicile)
            -- Ouverture du groupe Salon & Chambre Nous uniquement, les volets bébé s'ouvrent manuellement
            domoticz.devices(domoticz.helpers.GROUPE_VOLETS_SALON).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value)
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_NOUS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value)

        end    

        -- Activation du groupe (le niveau est suivant le mode Domicile) - spécifique pour les modes Ete & vacances
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)

        if(modeDomicile ~= '_vacs') then
            domoticz.log("[" .. domoticz.data.uuid .. "] En mode normal ou été, le scénario 2c Matin Vacances est ignoré", domoticz.LOG_INFO)
            return
        end
        
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        -- Présence, surcharge de l'ouverture comme le mode normal
        if(presenceDomicile == '') then
            modeDomicile= ''
        -- Absence
        elseif(presenceDomicile == '_abs') then
            -- absent : ouverture paramétrée pour les vacances
        end
        domoticz.log("[" .. domoticz.data.uuid .. "] Activation matin pour le mode ['" .. presenceDomicile .. "'/'" .. modeDomicile .."']", domoticz.LOG_INFO)
        ouvertureVoletMatinVacs(modeDomicile)

    end       
}