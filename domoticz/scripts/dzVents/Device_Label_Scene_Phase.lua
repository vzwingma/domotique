return
{
    on =
    {
        -- Evénement poussé par le changement de phase de scénario
        customEvents = { 'Scene Phase' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Scénario] "
    },
    execute = function(domoticz, item)

        -- Suivi de la phase du jour
        domoticz.data.uuid = item.json.uuid
        domoticz.log("[" .. domoticz.data.uuid .. "] Réception de l'événement [" .. item.customEvent .. "] : [" .. tostring(item.json.idx) .. "/" .. tostring(item.json.data) .. "]", domoticz.LOG_DEBUG)
        domoticz.globalData.scenePhase = item.json.data
        domoticz.devices(domoticz.helpers.DEVICE_STATUT_PHASE).updateText(item.json.data)
        
    end       
}