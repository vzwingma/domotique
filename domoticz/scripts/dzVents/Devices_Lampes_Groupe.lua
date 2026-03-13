-- ## Réalignement des groupes de Lumières depuis les items
-- Script déclenché quand une lumière individuelle change : réaligne le groupe parent.
return
{
    on =
    {
        devices = { 'Lumière TV', 'Prise TV', 'Lumière Salon', 'Lumière Cuisine' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Lumières Groupe] "
    },
    execute = function(domoticz, device)

    -- ### Réalignement groupe <- items ###
        domoticz.data.uuid = domoticz.helpers.uuid()
        local uuid = domoticz.data.uuid
        domoticz.log("[" .. uuid .. "] Changement lumière [" .. device.name .. "] -> réalignement groupe", domoticz.LOG_DEBUG)
        -- Réalignement du groupe Salon depuis ses items
        domoticz.helpers.verifyGroupeFromItem(
            domoticz.helpers.GROUPE_LUMIERES_SALON,
            { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_TV_2, domoticz.helpers.DEVICE_LAMPE_SALON, domoticz.helpers.DEVICE_LAMPE_CUISINE },
            uuid, domoticz)
    end
}
