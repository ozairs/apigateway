var rsa256Key = JSON.parse(context.get('rsa256Key.body'));
console.error('rsa keys %s', rsa256Key.keys[0]);
context.set('jwk-key', rsa256Key.keys[0]);