//Create a chat module to use.
(function () {
  window.Chat = {
    socket : null,

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
    send : function() {
      this.socket.emit('msg', {
/*        to: ['aaa'], TODO */
        name: $('#name').val(),
        msg: $('#message').val()
      });

      $('#message').val('');

      return false;
    }
  };
}());

