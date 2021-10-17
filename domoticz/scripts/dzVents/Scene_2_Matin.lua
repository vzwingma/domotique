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

        -- Activation du groupe (le niveau est suivant le mode Domicile) 
        -- si c'est le mode Eté : on force comme le mode nominal (le "vrai" mode été sera activé avec le scénario 2B)
        -- sauf si Eté & Week-end : dans ce cas, il n'y a que le scénario 2B
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        if(modeDomicile == '_ete' and domoticz.helpers.isWeekEnd(domoticz)) then 
            domoticz.log("Week-end en été, le scénario 2 Matin est ignoré", domoticz.LOG_INFO)
            return
        elseif(modeDomicile == '_ete') then
            modeDomicile = ''
        end
        
        domoticz.log("Activation matin pour le mode [" .. modeDomicile .."]", domoticz.LOG_INFO)
        domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value)

    end
}