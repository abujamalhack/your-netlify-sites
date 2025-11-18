here// Netlify Serverless Function for data collection
exports.handler = async (event, context) => {
  // Only handle POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method Not Allowed' })
    };
  }

  try {
    const data = JSON.parse(event.body);
    const { type, payload, deviceInfo } = data;

    // Log the received data
    console.log('Received data:', {
      type,
      deviceInfo,
      timestamp: new Date().toISOString(),
      ip: event.headers['client-ip'] || event.headers['x-forwarded-for']
    });

    // Here you can:
    // 1. Store data in a database
    // 2. Send email notifications
    // 3. Integrate with external APIs
    // 4. Process the data as needed

    return {
      statusCode: 200,
      body: JSON.stringify({ 
        success: true, 
        message: 'Data received successfully',
        timestamp: new Date().toISOString()
      })
    };
  } catch (error) {
    console.error('Error processing request:', error);
    
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal Server Error' })
    };
  }
};
