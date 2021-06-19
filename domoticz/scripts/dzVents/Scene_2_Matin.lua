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
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
        domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. modeDomicile).value)
    end       
}