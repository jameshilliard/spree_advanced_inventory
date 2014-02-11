$(document).ready(function () {
  var unsaved = false;
  var check_for_unsaved_changes = false;

  $(":input").change(function(){ 
    unsaved = true;
  });

  // Another way to bind the event
  $(window).bind('beforeunload', function() {
    if(unsaved) {
      return "You have unsaved changes on this page. Do you want to leave this page and discard your changes or stay on this page?";
    }
  });

  // Monitor dynamic inputs
  $(document).on('change', ':input', function() {
    if(check_for_unsaved_changes) {
      unsaved = true;
    }
    else {
      unsaved = false;
    }
  });

  $('.btn-success').click(function() {
      unsaved = false;
  });

  $('.icon-refresh').click(function() {
      unsaved = false;
  });

  $('.pagination a').click(function() {
      unsaved = false;
  });

});
