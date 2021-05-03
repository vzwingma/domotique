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
        -- directement intégrée dans Tydom_volets_setPosition

    end       
}