return
{
    on =
    {
        scenes = { 'Matin' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene PreReveil] "
    },
    execute = function(domoticz, scene)
        
        -- Ouverture du groupe de volets
        domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOn()
    end       
}