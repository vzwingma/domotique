return
{
    on =
    {
        devices = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[TYDOM Volets] "
    },
    execute = function(domoticz, item)
        -- # Commande de volets #
        local function updateVoletPosition(item, domoticz)
            local voletName = item.name
            local tydomIds  = domoticz.helpers.getTydomDeviceNumberFromDzItem(item.name, domoticz)
            local pOuverture = domoticz.helpers.getLevelFromState(item)
            domoticz.log("[" .. domoticz.data.uuid .. "] [" .. voletName .. "] set Position=" .. pOuverture .. "%", domoticz.LOG_INFO)
            local postData = { ['name'] = 'position', ['value'] = pOuverture }
            domoticz.helpers.callTydomBridgePUT(
                '/device/' .. tydomIds.deviceId .. '/endpoints/' .. tydomIds.endpointId,
                postData, domoticz.data.uuid, nil, domoticz)
        end

        -- Alignement des groupes de volets à partir d'un item modifié
        local function aligneGroupeVolet(itemName, domoticz)
            local uuid = domoticz.data.uuid
            if(itemName == domoticz.helpers.DEVICE_VOLET_SALON_G or itemName == domoticz.helpers.DEVICE_VOLET_SALON_D) then
                domoticz.helpers.verifyGroupeFromItem(
                    domoticz.helpers.GROUPE_VOLETS_SALON,
                    { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D },
                    uuid, domoticz)
            elseif(itemName == domoticz.helpers.DEVICE_VOLET_BEBE or itemName == domoticz.helpers.DEVICE_VOLET_NOUS) then
                domoticz.helpers.verifyGroupeFromItem(
                    domoticz.helpers.GROUPE_VOLETS_CHAMBRES,
                    { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS },
                    uuid, domoticz)
            end
            domoticz.helpers.verifyGroupeFromItem(
                domoticz.helpers.GROUPE_TOUS_VOLETS,
                { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS, domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D },
                uuid, domoticz)
        end

        domoticz.data.uuid = domoticz.helpers.uuid()

        -- Commande de position volet
        updateVoletPosition(item, domoticz)
        -- Réalignement des groupes
        aligneGroupeVolet(item.name, domoticz)

    end
}
