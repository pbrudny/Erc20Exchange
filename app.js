const request = require('request');
request.get('https://api.bitfinex.com/v2/book/tGNTETH/P0', (error, response, body) => console.log(body));
