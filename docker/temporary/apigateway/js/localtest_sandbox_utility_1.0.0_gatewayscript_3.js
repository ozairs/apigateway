context.message.body.readAsJSON
(function (error, response)
  {
    if (error)
    {
      return;
    }
    console.log("response %s", JSON.stringify(response));
    context.message.body.write(JSON.stringify(response));
  });