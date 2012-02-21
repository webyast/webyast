
$(document).ready(function() {
  $('#lang_current').hover(function() {
    $('#lang_menu').stop(true,true).delay(200).slideDown('fast');
  }, function() {
    $('#lang_menu').stop(true,true).slideUp('fast');
  });
});
