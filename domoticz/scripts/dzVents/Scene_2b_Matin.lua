-- ## Scripts de commande pour le matin en Semaine et en Week-end (mode spécial : présent en été ou présent en vacances)
return
{
    on =
    {
        scenes = { 'Matin 2' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Matin 2] "
    },
    execute = function(domoticz, scene)
        
        -- Activation du groupe (le niveau est suivant le mode Domicile) - spécifique pour les modes Ete & vacances
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        
        if(modeDomicile == '_ete' or modeDomicile == '_vacs' or presenceDomicile == '_abs') then
            domoticz.log("Activation matin spécial pour le mode [" .. presenceDomicile .. "/" .. modeDomicile .."]", domoticz.LOG_INFO)
            domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value)
        end        
    end       
}