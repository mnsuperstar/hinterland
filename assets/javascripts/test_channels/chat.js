function initializeChatChannel() {
  App.chat = App.cable.subscriptions.create("ChatChannel", {
    connected: function() {
      // Called when the subscription is ready for use on the server
      console.log('connected chat')
    },
    disconnected: function() {
      console.log('disconnected chat')
    },
    received: function(data) {
      $('<div>').html('<span>' + (new Date()).toString() + ':</span> <pre>' + JSON.stringify(data, null, 2) + '</pre>').prependTo('#ws_receives');
      if(data.status == 'parameter_missing') {
        console.log('missing parameters: ' + data.data.parameters)
      } else if(data.status == 'unauthenticated') {
        showCableLoginForm();
      }
      switch(data.action) {
        case 'init_chat':
          this.initiated_chat(data);
          break;
        case 'send_message':
          this.sent_message(data)
          break;
        default:
          console.log('received', data)
      }
    },
    init_chat: function(data) {
      this.perform('init_chat', data);
    },
    initiated_chat: function(data) {
      if(data.status == 'ok') {
        var peer_uid = null;
        $.each(data.data.chat.users, function(){
          if(this.uid != App.chat.current_user_uid) {
            peer_uid = this.uid;
            return false;
          }
        });
        if(!this.chats) this.chats = [];
        this.chats[peer_uid].uid = data.data.chat.uid;
        if(this.chats[peer_uid].pending_message) {
          this.send_message({message: {chat_uid: this.chats[peer_uid].uid, content: this.chats[peer_uid].message}});
          this.chats[peer_uid].pending_message = this.chats[peer_uid].message = null;
        }
      } else {
        alert('Failed to initiate chat. Errors: ' + data.data.error_messages.join(', '));
      }
    },
    send_message: function(data) {
      this.perform('send_message', data);
    },
    sent_message: function(data) {
      if(data.status == 'ok') {
        var text = data.data.message.content;
        if(data.data.message.image_content.url) text = '<img src="'+data.data.message.image_content.url+'">' + text
        $('<div>').html('<span>' + data.data.message.user.first_name + ':</span> ' + text).appendTo('#messages_container');
        this.perform('read_chat', {chat: {uid: data.data.message.chat_uid}});
      } else {
        alert('Failed to send message. Errors: ' + data.data.error_messages.join(', '));
      }
    },
    send_chat_message: function(uid, message) {
      if(!this.chats) this.chats = [];
      if(!this.chats[uid] || !this.chats[uid].uid) {
        this.init_chat({chat: { peer_uid: uid }});
        this.chats[uid] = { pending_message: true, message: message };
      } else {
        this.send_message({message: {chat_uid: this.chats[uid].uid, content: message}});
      }
    }
  });
}
