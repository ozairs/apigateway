if (context.get('decoded.claims')) {
	var response = { 
	    "active": true, 
	    "jwt-claims" : context.get('decoded.claims')
	};
	
	context.set('message.body', response);
	context.set('message.status.code', 200);
	console.info ('>> oauth introspection is successful %s', JSON.stringify(context.get('decoded.claims')));
}
else {
    context.set('message.status.code', 200);
	
	console.error ('>> oauth introspection failed %s', JSON.stringify(JSON.stringify(context.get('decoded.claims'))));
}