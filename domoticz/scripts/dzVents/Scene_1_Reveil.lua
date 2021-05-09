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
        
        -- Récupération des paramètres et activation suivant le mode de domicile
        local voletName = domoticz.helpers.DEVICE_VOLET_NOUS
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        -- Activation seulement si mode par défaut ou Eté
        if(modeDomicile == '' or modeDomicile == '_ete') then
            local paramOuvertureReveil = domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_REVEIL).value
            local level = math.max(paramOuvertureReveil, domoticz.devices(voletName).level)
            
            -- PréOuverture du volet de la chambre, à 5% si fermé - reste à hauteur si plus ouvert
            domoticz.log("Ouverture du volet "..voletName .. " : " .. level .. "%")
            domoticz.devices(voletName).setLevel(level)
        else
            domoticz.log('Personne à la maison, pas d\'ouverture du volet [' .. voletName .. ']')
        end
    end       
}