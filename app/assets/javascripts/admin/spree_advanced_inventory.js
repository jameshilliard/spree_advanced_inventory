$(document).ready(function () {
  var unsaved = false;

  $(":input").change(function(){ 
    unsaved = true;
  });

  // Another way to bind the event
  $(window).bind('beforeunload', function() {
      if(unsaved){
          return "You have unsaved changes on this page. Do you want to leave this page and discard your changes or stay on this page?";
      }
  });

  // Monitor dynamic inputs
  $(document).on('change', ':input', function(){ 
      unsaved = true;
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
