const express = require('express');
const app = express();
const invoke = require('./sdk_app/invoke');
const query = require('./sdk_app/query');

app.post('/submit', (req, res) => {
   invoke();
   res.send('Hello World');
 })
 app.post('/query', (req, res) => {
   responseJson = query();
   console.log();
   res.send('Hello World Query' + responseJson);
   
   
 })
 
 let server = app.listen(5500, () => {
    var host = server.address().address
    var port = server.address().port
    console.log("Example app listening at http://%s:%s", host, port)
 })
 