-- ## Scripts de commande des groupes de Lumières
-- Script déclenché pour chaque groupe de lumières : lance les niveaux et statuts des lumières constituant le groupe (ou le groupe de groupe)
return
{
    on =
    {
        devices = { 'Lumière TV', 'Lumière Salon', 'Lumière Cuisine' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Lumières Groupe] "
    },
    -- Activation du groupe de lumières
    execute = function(domoticz, devices)
    -- ### Fonctions internes ###

        -- Alignement des groupes de lumières
        -- Vérification de la valeur du groupe // à ses items (les autres groupes)
        function verifyGroupeFromItem(groupe, items, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Vérification des items du groupe [" .. groupe .. "]", domoticz.LOG_DEBUG )
            local valeur = nil
            local sameLevel = false
            for _, pair in pairs(items) do
                domoticz.log("[" .. domoticz.data.uuid .. "]  > " .. pair .. ":" .. tostring(domoticz.devices(pair).state) .."/" .. tostring(domoticz.devices(pair).level), domoticz.LOG_DEBUG )
                local deviceValeur = domoticz.devices(pair).level
                if(domoticz.devices(pair).state == 'Off') then 
                    deviceValeur = 0
                end
                if(valeur == nil or valeur == deviceValeur ) then
                    sameLevel = true
                elseif(valeur ~= deviceValeur) then
                    sameLevel = false
                end
                valeur = deviceValeur 
            end
            -- Réalignement du groupe si les lumières du groupe ont la même valeur et différentes de celle du groupe
            if(sameLevel == true and domoticz.devices(groupe).level ~= valeur) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Réalignement des items du groupe [" .. groupe .. "] " .. domoticz.devices(groupe).level .. " > " .. valeur .. "%", domoticz.LOG_INFO) 
                domoticz.devices(groupe).setLevel(valeur).silent()
            end
        end


    -- ### Lancement du scénario du Groupe ###
        domoticz.data.uuid = domoticz.helpers.uuid()
        -- Alignement du groupe de lumières
        verifyGroupeFromItem(domoticz.helpers.GROUPE_LUMIERES_SALON, { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_TV_2, domoticz.helpers.DEVICE_LAMPE_SALON , domoticz.helpers.DEVICE_LAMPE_CUISINE } , domoticz)
    end       
}