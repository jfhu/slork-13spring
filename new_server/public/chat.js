//Create a chat module to use.
(function () {
  window.Chat = {
    socket : null,
    is_admin : false,
    is_projected : false,
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

      if ('private' in data && window.Chat.is_projected) {
          return;
      }

      if (!window.Chat.is_projected && data.act != $('#act').val()) {
          return;
      }

      var msg = $('<div class="msg"></div>');

      if ('to' in data || 'private' in data) {
          msg.addClass('private');
      }

      if (name[0] == '_') {
          msg.addClass('highlighted');
          name = name.substr(1);
      }

      msg.append('<span class="name">' + name + ':</span> ')
         .append('<span class="text">' + data.msg + '</span>');

      if (!window.Chat.is_projected) {
          $('#messages').append(msg);
          $('#messages')
            .animate({scrollTop: $('#messages').prop('scrollHeight')}, 100);
      } else {
          if ('private' in data || 'to' in data) return;
          var id = '#messages_' + data.act;
          console.log(id);
          $(id).append(msg);
          $(id)
            .animate({scrollTop: $(id).prop('scrollHeight')}, 100);
      }
    },

    //Sends a message to the server,
    //then clears it from the textarea
    send : function(msg) {
      var obj = {
        name: $('#name').val(),
        msg: $('#message').val(),
        act: $('#act').val()
      };

      console.log(msg);
      if (msg) obj['msg'] = msg;

      // TODO: temporary
      if (this.is_admin) {
        var str = $('#to').val();
        str = str.split(',');
        for (var i = 0; i < str.length; i++) {
            str[i] = $.trim(str[i]);
        }
        str = str.filter(function(d){return d!==''});
        console.log(str);
        this.selected_clients = str;
      }

      if (this.is_admin && this.selected_clients.length > 0) {
        obj['to'] = this.selected_clients;
      }
      if (this.is_admin && $('#private').attr('checked')) {
          obj['private'] = true;
      }
      this.socket.emit('msg', obj);

      $('#message').val('');

      return false;
    }
  };
}());

