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
        -- Activation du groupe (le niveau est suivant le mode Domicile)
        domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOn()
    end       
}