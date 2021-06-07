return
{
    on =
    {
        httpResponses = { 'global_HTTP_response' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[HTTP Response] "
    },
    execute = function(domoticz, item)
        -- Callback
        if (item.isHTTPResponse) then
            if(item.isOk or item.statusCode == 200) then
                domoticz.log(item.statusCode .. " - " .. item.statusText)
                domoticz.log(item.data) 
            else 
                domoticz.log("Erreur lors de l'appel HTTP : " .. item.statusCode .. " - " .. item.statusText, domoticz.LOG_ERROR)
            end
        end        
    end       
}