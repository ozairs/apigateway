context.message.body.readAsJSON(function (error, json) {
    
    console.info("json %s", JSON.stringify(json));
    
    if (json && context.message.statusCode == '404') {
        console.error("throwing apim error %s", JSON.stringify(json.status.code));
    		context.reject('ConnectionError', 'Failed to retrieve data');
            context.set('message.status.code', 500);
    }
    // else if (json) {
    //     json.plan = context.get('plan.name');
    // }
    
    context.message.header.set('Authorization', context.get('generated.jwt'));
    context.message.header.set('plan', context.get('plan.name'));
    
    console.error("jwt token %s", context.get('generated.jwt'));
    console.error("plan name %s", context.get('plan.name'));

    //set the runtime API context
    context.set('message.body', json);
});