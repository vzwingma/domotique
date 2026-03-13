-- ## Scripts de commande des groupes de volets
-- Script déclenché pour chaque groupe de volet : lance les niveaux et statuts des volets constituant le groupe (ou le groupe de groupe)
return
{
    on =
    {
        devices = { '[Grp] Volets Salon', '[Grp] Tous Volets', '[Grp] Volets Chambres' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Groupe Volets] "
    },
    -- Activation du groupe de volets
    execute = function(domoticz, group)
    -- ### Fonctions internes ###
        -- Recherche des volets du groupe
        local function getVoletsNameFromGroup(groupName)
            domoticz.log("[" .. domoticz.data.uuid .. "] Recherche des volets du groupe [" .. groupName .. "]", domoticz.LOG_DEBUG)
            if(groupName == domoticz.helpers.GROUPE_TOUS_VOLETS) then
                return { domoticz.helpers.DEVICE_VOLET_NOUS, domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }
            elseif(groupName == domoticz.helpers.GROUPE_VOLETS_CHAMBRES) then
                return { domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_NOUS }
            elseif(groupName == domoticz.helpers.GROUPE_VOLETS_SALON) then
                return { domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }
            else
                return {}
            end
        end

    -- ### Lancement du scénario du Groupe ###
        domoticz.data.uuid = domoticz.helpers.uuid()
        local uuid     = domoticz.data.uuid
        local voletsName = getVoletsNameFromGroup(group.name)
        local levelSet   = domoticz.helpers.getLevelFromState(group)
        domoticz.log("[" .. uuid .. "] Groupe [" .. group.name .. "] -> " .. group.state .. " : " .. levelSet .. "%", domoticz.LOG_INFO)

        for _, voletName in ipairs(voletsName) do
            domoticz.log("[" .. uuid .. "] Volet [" .. voletName .. "] -> " .. levelSet .. "%", domoticz.LOG_INFO)
            domoticz.devices(voletName).setLevel(levelSet)
        end
        -- Alignement du groupe de groupe depuis les devices directs (source unique, cohérente avec Tydom_volets_setPosition)
        domoticz.helpers.verifyGroupeFromItem(domoticz.helpers.GROUPE_TOUS_VOLETS, { domoticz.helpers.DEVICE_VOLET_NOUS, domoticz.helpers.DEVICE_VOLET_BEBE, domoticz.helpers.DEVICE_VOLET_SALON_G, domoticz.helpers.DEVICE_VOLET_SALON_D }, uuid, domoticz)
    end
}
