return
{
    on =
    {
        scenes = { 'Reveil' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Reveil] "
    },
    execute = function(domoticz, scene)
        
        -- Récupération des paramètres
        local paramOuvertureReveil = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_REVEIL).value
        
        -- PréOuverture du volet de la chambre
        local voletName = domoticz.helpers.DEVICE_VOLET_NOUS
        local level = math.max(paramOuvertureReveil, domoticz.devices(voletName).level)
        domoticz.log("Ouverture du volet "..voletName .. " : " .. level .. "%")
        domoticz.devices(voletName).setLevel(level)
    end       
}