const express = require('express');
const morgan = require('morgan');
const path = require('path');
const vhost = require('vhost');


const port = 80;


// development.computatus.com
const app_computatus = express();
app_computatus.use(morgan('combined'));
app_computatus.use("/.well-known", express.static(path.join(__dirname, '.well-known')));
// app_computatus.all('*', function (req, res) { res.redirect('https://development.computatus.com' + req.url) });

// development.eseme.one
const app_eseme = express();
app_eseme.use(morgan('combined'));
app_eseme.use("/.well-known", express.static(path.join(__dirname, '.well-known')));
// app_eseme.all('*', function (req, res) { res.redirect('https://development.eseme.one' + req.url) });


const app = express();

// dev1
app.use(vhost('development.computatus.com', app_computatus));
app.use(vhost('development.eseme.one', app_eseme));

// prod1
app.use(vhost('computatus.com', app_computatus));
app.use(vhost('www.computatus.com', app_computatus));
app.use(vhost('arithmetixcrush.computatus.com', app_computatus));
app.use(vhost('eseme.one', app_eseme));
app.use(vhost('www.eseme.one', app_eseme));


const http = require('http');
http.createServer(app)
	.listen(port, () => {
		console.log('\x1b[0;32mServer started.\x1b[0m');
		console.log(`\nPort:\t${port}`);
		console.log(`\Start Time: ${new Date()}`);
	});

