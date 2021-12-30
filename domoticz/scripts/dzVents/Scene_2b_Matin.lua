-- ## Scripts de commande pour le matin en Semaine et en Week-end (mode spécial : présent en été ou présent en vacances)
return
{
    on =
    {
        scenes = { 'Matin 2' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Matin 2] "
    },
    execute = function(domoticz, scene)
        
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        domoticz.data.uuid = domoticz.helpers.uuid()

        -- Activation du groupe (le niveau est suivant le mode Domicile) - spécifique pour les modes Ete & vacances
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        
        -- Activation du mode suivant la présence au domicile et le mode
        local modeVolet = ''
        -- Présence
        if(presenceDomicile == '') then
            modeVolet = presenceDomicile
            -- en été : surcharge pour redescendre les volets
            if(modeDomicile == '_ete') then
               modeVolet = modeDomicile
            end
        -- Absence
        elseif(presenceDomicile == '_abs') then
            -- en vacances : surcharge pour redescendre les volets
            if(modeDomicile == '_vacs') then
               modeVolet = modeDomicile 
            end
        end

        domoticz.log("[" .. domoticz.data.uuid .. "] Activation matin 2 pour le mode [" .. presenceDomicile .. "/" .. modeDomicile .."]", domoticz.LOG_INFO)
        domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeVolet).value)
    end       
}