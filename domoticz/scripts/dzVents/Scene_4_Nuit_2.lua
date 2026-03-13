return
{
    on =
    {
        scenes = { 'Nuit 2' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Nuit] "
    },
    execute = function(domoticz, scene)

        -- Suivi de la phase du jour (via événement, comme les autres scènes)
        domoticz.data.uuid = domoticz.helpers.uuid()
        domoticz.emitEvent('Scene Phase', { idx = 4, data = scene.name, uuid = domoticz.data.uuid })
        -- Extinction des lampes
        domoticz.emitEvent('Scenario Nuit', { data = false, uuid = domoticz.data.uuid }) -- event vers les devices lampes
    end       
}