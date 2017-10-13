// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the rails generate channel command.
//
//= require action_cable
//= require_self
//= require_tree ./test_channels

function initializeActionCable() {
  $('.cable-section').hide();
  window.App = {};
  App.cable = ActionCable.createConsumer(prompt('Please enter cable ws url:', $('#cable_data').data('url')));
}
