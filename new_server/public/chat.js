//Create a chat module to use.
(function () {
  window.Chat = {
    socket : null,
    is_admin : false,
    selected_clients : [],
    client_mapping: {},

    initialize : function(socketURL) {
      this.socket = io.connect(socketURL);

      //Send message on button click or enter
      $('#send').click(function() {
        Chat.send();
      });

      $('#message').keyup(function(evt) {
        if ((evt.keyCode || evt.which) == 13) {
          Chat.send();
          return false;
        }
      });

      //Process any incoming messages
      this.socket.on('new', this.add);

      // Admin Stuff
      if (this.is_admin) {
          this.socket.on('name', function(data) {
              window.Chat.client_mapping[data.key] = data.name;
          });
      }

    },

    //Adds a new message to the chat.
    add : function(data) {
      var name = data.name;

      // if this message is not for me, ignore it
      if ('to' in data) {
          var localname = $('#name').val() || 'anonymous';
          if (localname != name &&
              $.inArray(localname, data.to) < 0) {
                  return;
          }
      }

      var msg = $('<div class="msg"></div>');

      if ('to' in data) {
          msg.addClass('private');
      }

      if (name[0] == '_') {
          msg.addClass('highlighted');
          name = name.substr(1);
      }

      msg.append('<span class="name">' + name + ':</span> ')
         .append('<span class="text">' + data.msg + '</span>');

      $('#messages').append(msg);
      $('#messages')
        .animate({scrollTop: $('#messages').prop('scrollHeight')}, 100);
    },

    //Sends a message to the server,
    //then clears it from the textarea
    send : function(msg) {
      var obj = {
        name: $('#name').val(),
        msg: $('#message').val()
      };

      console.log(msg);
      if (msg) obj['msg'] = msg;

      if (this.is_admin && this.selected_clients.length > 0) {
        obj['to'] = selected_clients;
      }
      this.socket.emit('msg', obj);

      $('#message').val('');

      return false;
    }
  };
}());

