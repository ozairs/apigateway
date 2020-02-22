let claims = context.get( 'oauth.processing.jwt.claims' );
let errorText = undefined;
if (claims === undefined)
{
  errorText = 'No JWT claims found';
}
else
{
   let subject = claims.sub;
  if (subject === undefined)
  {
    errorText = 'JWT subject not found';
  }
  else
  {
    context.set( 'oauth.processing.resource_owner', subject );
  }
}

if (errorText !==undefined)
{
  console.error('JWT Grant Type Error: ' + errorText);
  context.message.statusCode = '400 Bad Request';
  context.reject('JWT Error', 'JWT Error: ' + errorText);
}