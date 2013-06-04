var express = require('express');
var app = express();
var server = require('http').createServer(app);
var io = require('socket.io').listen(server);
var client_mapping = {};

server.listen(8000);

app.use("/", express.static(__dirname + '/public'));

io.sockets.on('connection', function (socket) {
  socket.on('msg', function (data) {
    if (!data.name) {
        data.name = "anonymous";
    }
    var address = socket.handshake.address;
    var client_key = address.address + ":" + address.port;
    if (!(client_key in client_mapping) || data.name != client_mapping[client_key]) {
        console.log("Client " + client_key + " connected with name " + data.name);
        io.sockets.emit('name', {'key':client_key, 'name':data.name});
        client_mapping[client_key] = data.name;
    }
    io.sockets.emit('new', data);
  });
});
