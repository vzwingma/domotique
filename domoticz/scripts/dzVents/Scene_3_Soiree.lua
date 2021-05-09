return
{
    on =
    {
        scenes = { 'Soiree' },
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Soiree] "
    },
    execute = function(domoticz, scene)
        -- Fermeture du groupe de volets (quel que soit le mode Domicile)
        domoticz.groups(domoticz.helpers.GROUPE_TOUS_VOLETS).switchOff()
  
    end       
}