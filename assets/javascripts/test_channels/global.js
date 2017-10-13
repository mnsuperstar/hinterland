function initializeGlobalChannel() {
  console.log('init global')
  App.global = App.cable.subscriptions.create("GlobalChannel", {
    connected: function() {
      // Called when the subscription is ready for use on the server
      console.log('connected global')
      $('#cable_status').text('Connected to ' + App.cable.url);
      var auth_token = getCookie('cable_auth_token');
      if(auth_token) {
        this.authenticate({auth_token: auth_token});
      } else {
        showCableLoginForm();
      }
    },
    authenticate: function(data) {
      this.perform('authenticate', data);
    },
    authenticated: function(data) {
      if(data.status == 'ok') {
        console.log('authenticated. user: ' + data.data.user.email);
        if(!App.chat) initializeChatChannel();
        showCableMessages(data.data.user.email);
        App.chat.current_user_uid = data.data.user.uid;
        $('#cable_chat_user')
          .find('option:disabled').prop('disabled', false).end()
          .find('option[value="'+data.data.user.uid+'"]').prop('disabled', true);
      } else {
        showCableLoginForm();
        alert('Failed to authenticate. Errors: ' + data.data.error_messages.join(', '));
      }
    },
    unauthenticate: function() {
      this.perform('unauthenticate');
    },
    unauthenticated: function(data) {
      if(data.status == 'ok') {
        setCookie('cable_auth_token', null, -1);
        if(App.chat) {
          App.chat.unsubscribe();
          App.chat = null;
        }
      } else {
        showCableMessages();
      }
    },
    disconnected: function() {
      console.log('disconnected global')
      hideCableSections();
      if(App.chat) {
        App.chat.unsubscribe();
        App.chat = null;
      }
      $('#cable_status').text('Disconnected, trying to reconnect...');
      console.log('disconnected, trying to reconnect...');
    },
    received: function(data) {
      $('<div>').html('<span>' + (new Date()).toString() + ':</span> <pre>' + JSON.stringify(data, null, 2) + '</pre>').prependTo('#ws_receives');
      if(data.status == 'parameter_missing') {
        console.log('missing parameters: ' + data.data.parameters)
      } else if(data.status == 'unauthenticated') {
        showCableLoginForm();
      }
      switch(data.action) {
        case 'authenticate':
          this.authenticated(data);
          break;
        case 'unauthenticate':
          this.unauthenticated(data);
          break;
        default:
          console.log('received', data)
      }
    }
  });
}
