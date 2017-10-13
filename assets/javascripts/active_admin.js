//= require active_admin/base
//= require select2
//= require Chart.bundle
//= require chartkick
//= require activeadmin_sortable_table
//= require open_location

$(function(){
  if($('body.admin_adventures.show').length) {
    $( '#adventure_image tbody' ).disableSelection();
    $( '#adventure_image tbody' ).sortable({
      axis: 'y',
      cursor: 'move',
      update: function(event, ui) {
        sendSortRequestOfModel('adventures', 'adventure_image');
      }
    });
  }
  $('.select2').select2({
    allowClear: true
  });
  OpenLocation.init();
});

function sendSortRequestOfModel(model_name, sortable_list) {
  var $sortable = $('#' + sortable_list + ' tbody');
  var formData = $sortable.sortable('serialize');

  formData += '&' + $('meta[name=csrf-param]').attr('content') +
    '=' + encodeURIComponent($('meta[name=csrf-token]').attr('content'));

  $.ajax({
    type: 'post',
    data: formData,
    dataType: 'script',
    url: '/admin/' + model_name + '/sort',
    success: function(){
      $sortable.find('.col-order_number').each(function(i){
        $(this).text(i+1);
      });
      $sortable.find('tr').each(function(i){
        var cName = (i % 2) ? 'odd' : 'even';
        $(this).removeClass('odd even').addClass(cName);
      });
    },
    error: function(){
      alert('Unable to update order number.');
      window.location.reload();
    }
  });
}
