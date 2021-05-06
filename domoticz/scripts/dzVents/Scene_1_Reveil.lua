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
        -- PréOuverture du volet de la chambre
        local voletName = domoticz.helpers.DEVICE_VOLET_NOUS
        local level = 5
        domoticz.log("Ouverture du volet "..voletName .. " : " .. level .. "%")
        domoticz.devices(voletName).setLevel(level)
    end       
}