//= require test_cable

$(function() {
  var $loginForm = $('#cable_login_form');
  if(!$loginForm.length) return;

  initializeActionCable();

  App.cable.connection.oldSend = App.cable.connection.send;
  App.cable.connection.send = function(data) {
    $('<div>').html('<span>' + (new Date()).toString() + ':</span> <pre>' + JSON.stringify(data, null, 2) + '</pre>').prependTo('#ws_sends');
    App.cable.connection.oldSend.apply(this, [data]);
  }
  initializeGlobalChannel();

  var auth_token = getCookie('cable_auth_token');
  $loginForm.on('submit', function(e){
    e.preventDefault();
    var $authToken = $(this).find('#auth_token');
    auth_token = $authToken.val();
    setCookie('cable_auth_token', auth_token);
    $authToken.val('');
    if(App.global) {
      App.global.authenticate({auth_token: auth_token});
    }
  });
  $('#cable_logout').click(function(e){
    e.preventDefault();
    auth_token = null;
    App.global.unauthenticate();
    showCableLoginForm();
  });

  $('#cable_test_form_message').submit(function(e){
    e.preventDefault();
    var uid = $('#cable_chat_user').val();
    var $message = $('#chat_message');
    App.chat.send_chat_message(uid, $message.val());
    $message.val('');
  });

  $('.clear-link').click(function(e){
    e.preventDefault();
    $(this).next('div').text('');
  });
});

function showCableLoginForm() {
  $('.cable-section:not(#cable_login_form)').slideUp();
  $('#cable_login_form').slideDown();
}

function showCableMessages(user) {
  $('.cable-section:not(#cable_messages)').slideUp();
  $('#cable_messages').slideDown();
  if(user) $('#cable_user').text(user);
}

function hideCableSections() {
  $('.cable-section').slideUp();
}

function setCookie(c_name,value,exdays){
  var exdate=new Date();
  exdate.setDate(exdate.getDate() + exdays);
  var c_value=escape(value) + ((exdays==null) ? "" : "; expires="+exdate.toUTCString())+"; path=/";
  document.cookie=c_name + "=" + c_value;
}

function getCookie(c_name){
  var c_value = document.cookie;
  var c_start = c_value.indexOf(" " + c_name + "=");
  if (c_start == -1){
    c_start = c_value.indexOf(c_name + "=");
  }
  if (c_start == -1){
    c_value = null;
  } else {
    c_start = c_value.indexOf("=", c_start) + 1;
    var c_end = c_value.indexOf(";", c_start);
    if (c_end == -1){
      c_end = c_value.length;
    }
    c_value = unescape(c_value.substring(c_start,c_end));
  }
  return c_value;
}
