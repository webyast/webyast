
$(document).ready(function() {
  // position the menu exactly below the label
  $('#lang_menu').css('top', $('#lang_current').outerHeight());

  $('#lang_current').hover(function() {
    $('#lang_menu').stop(true,true).delay(200).slideDown('fast');
  }, function() {
    $('#lang_menu').stop(true,true).slideUp('fast');
  });
});
