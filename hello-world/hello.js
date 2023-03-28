// Lambda function code

module.exports.handler = async (event) => {
    console.log('Lambda Event : ', event);
    let responseMessage = 'Hello, World!!!';
  
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: responseMessage,
      }),
    }
  }
  