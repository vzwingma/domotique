-- ## Scripts de commande pour le matin en Semaine et en Week-end (mode normal : présent ou absent)
return
{
    on =
    {
        scenes = { 'Matin' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Matin] "
    },
    execute = function(domoticz, scene)
        
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name

        -- Activation du groupe (le niveau est suivant la présence Domicile) 
        -- sauf si Eté & Week-end : dans ce cas, il n'y a que le scénario 2B
        -- sauf si Vacances : dans ce cas, il n'y a que le scénario 2B
        -- Récupération des paramètres et activation suivant le mode de domicile
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)

        if(modeDomicile == '_ete' and domoticz.helpers.isWeekEnd(domoticz)) then 
            domoticz.log("Week-end en été, le scénario 2 Matin est ignoré", domoticz.LOG_INFO)
            return
        elseif(modeDomicile == '_vacs') then 
            domoticz.log("En mode vacances, le scénario 2 Matin est ignoré", domoticz.LOG_INFO)
            return
        end
        -- Sinon activation suivant présence
        
        domoticz.log("Activation matin pour le mode [" .. presenceDomicile .. "/" .. modeDomicile .."]", domoticz.LOG_INFO)
        domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. presenceDomicile).value)
    end
}