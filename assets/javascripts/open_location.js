var OpenLocation = (function(){
  'use strict'
  var
  $location, $state, $city,

  init = function(){
    _initVar();
    _initEvent();
  },

  _initVar = function(){
    $location = $('#open_location_location_id');
    $state = $('#open_location_state');
    $city = $('#open_location_city');
  },

  _initEvent = function(){
    $location.on('change', function(){
      if($location.val() === ''){
        $state.val('');
        $city.val('');
      }else{
        var url = '/admin/locations/' + $location.val() + '/get_location'
        $.get(url, null, null, 'json').done(_autoCompleteOpenLocationCallback);
      }
    });

    $location.select2({
      placeholder: 'select location',
      allowClear: true
    });
  },

  _autoCompleteOpenLocationCallback = function(data){
    $state.val(data.state);
    $city.val(data.city);
  }

  return {
    init: init
  }
})();
