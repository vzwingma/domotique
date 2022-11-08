return {
    on = {
        devices = { 'Porte' , 'Balcon D', 'Balcon G', 'Fenêtre bébé' },
        customEvents = { 'Supervision Ouverture' }
    },
    data = {
        -- Délai en seconde avant alarme
        supervisionDelay = { initial = 30 },
        -- 
        compteurDelaiOuverturePorte = { initial = 0 },
        compteurDelaiOuvertureBalconG = { initial = 0 },
        compteurDelaiOuvertureBalconD = { initial = 0 },
        compteurDelaiOuvertureBebe = { initial = 0 }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Ouverture] "
    },
    -- Fonction chargée de surveiller l'ouverture et la fermeture d'une porte ou d'une fenêtre
    -- Si ouvert trop longtemps : Alerte
    execute = function(domoticz, item)
        
        -- Déclenchement du timeout, la porte doit être fermée avant xx secondes sinon alerte
        function startSurveillance(device, uuid, domoticz)
            domoticz.log("startSurveillance :: " .. device.name)
            incrCompteurDelaiOuverture(device.name, 1, domoticz)
            local delaiSurveillance = getCompteurDelaiOuverture(device.name, domoticz) * domoticz.data.supervisionDelay
            domoticz.emitEvent('Supervision Ouverture', { deviceName = device.name, uuid = uuid } ).afterSec(delaiSurveillance)
        end
        
        -- Fin du timeout, on vérifie l'état. Si toujours ouverte, alerte et relance du timeout
        function checkStateAfterTimeout(event, domoticz)
            local item = domoticz.devices(event.json.deviceName)
            local uuid = event.json.uuid
            local compteurDelaiOuverture = getCompteurDelaiOuverture(event.json.deviceName, domoticz)
            local delaiTotal = ((compteurDelaiOuverture * (compteurDelaiOuverture + 1))/2) * domoticz.data.supervisionDelay
            domoticz.log("[" .. uuid .. "] [" .. event.json.deviceName .. "] Etat courant après " .. delaiTotal .. " s : " .. item.state, domoticz.LOG_DEBUG)
            -- Si toujours Ouvert, on alerte
            if(item.active) then
                notifyAlerteOuverture(item, delaiTotal, uuid, domoticz)
                -- et relance de la supervision
                startSurveillance(item, uuid, domoticz)
            -- sinon rien - raz du compteur
            else
                compteurDelaiOuverture = 0
            end
        end

        -- Notification de l'alerte
        function notifyAlerteOuverture(item, delaiTotal, uuid, domoticz)
            domoticz.helpers.notify(item.name .. ' est ouvert depuis plus de ' .. delaiTotal .. 's', uuid, domoticz)
            domoticz.log("[" .. uuid .. "] " .. item.name .. ' est ouvert depuis plus de ' .. delaiTotal .. 's')
        end
        
        
        -- Retourne le compteur délai d'ouverture suivant l'item
        function getCompteurDelaiOuverture(itemName, domoticz) 
            if(itemName == 'Porte') then 
               return domoticz.data.compteurDelaiOuverturePorte
            elseif(itemName == 'Balcon G') then
                return domoticz.data.compteurDelaiOuvertureBalconG
            elseif(itemName == 'Balcon D') then
                return domoticz.data.compteurDelaiOuvertureBalconD                
            elseif(itemName == 'Fenêtre bébé') then
                return domoticz.data.compteurDelaiOuvertureBebe                
            
            end
        end        

        -- incrémente le compteur délai d'ouverture suivant l'item
        function incrCompteurDelaiOuverture(itemName, increment, domoticz) 
            local compteurDelaiOuverture = getCompteurDelaiOuverture(itemName, domoticz)
            if(increment == 0) then
               compteurDelaiOuverture = 0 
            else
                compteurDelaiOuverture = compteurDelaiOuverture + increment
            end
            
            if(itemName == 'Porte') then 
               domoticz.data.compteurDelaiOuverturePorte = compteurDelaiOuverture
            elseif(itemName == 'Balcon G') then
                domoticz.data.compteurDelaiOuvertureBalconG = compteurDelaiOuverture
            elseif(itemName == 'Balcon D') then
                domoticz.data.compteurDelaiOuvertureBalconD = compteurDelaiOuverture
            elseif(itemName == 'Fenêtre bébé') then
                domoticz.data.compteurDelaiOuvertureBebe = compteurDelaiOuverture
            end
        end          
        
        -- Etat : Open ou Closed d'une porte ou d'une fenêtre
        if(item.isDevice) then
            local uuid = domoticz.helpers.uuid()
            domoticz.log("[" .. uuid .. "] Changement d'état " .. item.name .. "::".. item.state, domoticz.LOG_DEBUG)
            if(item.active == true) then
                domoticz.log("[" .. uuid .. "] Ouverture de [" .. item.name .. "]", domoticz.LOG_INFO)
                domoticz.helpers.notify("Ouverture de [" .. item.name .. "]", uuid, domoticz)
                if(item.name == 'Porte') then
                    startSurveillance(item, uuid, domoticz)
                    
                end
            else
                domoticz.log("[" .. uuid .. "] Fermeture de [" .. item.name .. "]", domoticz.LOG_INFO)
                -- domoticz.helpers.notify("Fermeture de [" .. item.name .. "]", uuid, domoticz)
                incrCompteurDelaiOuverture(item.name, 0, domoticz)
                if(item.name == 'Porte') then
                    domoticz.emitEvent('freebox_initsession').afterSec(20)
                end
            end
        -- Déclenchement du timer
        elseif(item.isCustomEvent ) then
            checkStateAfterTimeout(item, domoticz)
        end

    end
}
