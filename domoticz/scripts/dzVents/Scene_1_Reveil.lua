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
        
        -- Ouverture du groupe de volets
        domoticz.devices(domoticz.helpers.DEVICE_VOLET_SALON_G).switchOff()
    end       
}