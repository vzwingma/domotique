return
{
    on =
    {
        scenes = { 'Reveil' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Reveil] "
    },
    execute = function(domoticz, scene)
        
        -- Suivi de la phase du jour
        domoticz.globalData.scenePhase = scene.name
        domoticz.data.uuid = domoticz.helpers.uuid()
        
        -- Récupération des paramètres et activation suivant le mode de domicile
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)

        local voletName = domoticz.helpers.DEVICE_VOLET_NOUS        
        -- Activation seulement si Présent & mode Normal ou Eté
        if(presenceDomicile == '' and (modeDomicile == '' or modeDomicile == '_ete')) then
            local paramOuvertureReveil = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_REVEIL).value
            local level = math.max(paramOuvertureReveil, domoticz.helpers.getLevelFromState(domoticz.devices(voletName)))
            
            -- PréOuverture du volet de la chambre, à 5% si fermé - reste à hauteur si plus ouvert
            domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture du volet " .. voletName .. " : " .. level .. "%", domoticz.LOG_INFO)
            domoticz.devices(voletName).setLevel(level)
        else
            domoticz.log("[" .. domoticz.data.uuid .. "] Personne à la maison ou vacances, pas d\'ouverture du volet [" .. voletName .. "]", domoticz.LOG_INFO)
        end
    end       
}