context.message.body.readAsJSON(function (error, json) {
    
    console.info("json %s", JSON.stringify(json));
    
    if (json && context.message.statusCode == '404') {
        console.error("throwing apim error %s", JSON.stringify(json.status.code));
    		context.reject('ConnectionError', 'Failed to retrieve data');
            context.set('message.status.code', 500);
    }
    
    //add new attributes to the payload body
    json.platform = 'Powered by IBM API Connect';
    
    //set the runtime API context
    context.set('message.body', json);
    
    //add a new response header
    context.set('message.headers.Platform', 'Powered by IBM API Connect');
});