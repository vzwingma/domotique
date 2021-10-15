return
{
    on =
    {
        scenes = { 'Matin Eté' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Matin] "
    },
    execute = function(domoticz, scene)
        
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        
        -- Activation du groupe (le niveau est suivant le mode Domicile) - spécifique pour le mode Ete : on rebaisse le niveau
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        if(modeDomicile == '_ete') then
            domoticz.log("Activation matin été pour le mode [" .. modeDomicile .."]")
            domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value)
        end
    end       
}