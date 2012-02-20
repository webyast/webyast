/*
#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc.
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation.
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++
*/

// slide between index page and interface selection page
$(function(){
  $("a#iface_selection_link").live("click", function(event) {
    event.preventDefault();
    $("#pages").stop().delay(400).animate({"margin-left":-960},200)
    return false;
  })

  $("a#iface_back_link").live("click", function(event) {
    event.preventDefault();
    $("#pages").stop().delay(400).animate({"margin-left":0},200)
    return false;
  })
});

// Validate form before submit
function is_valid() {
  var $form = $('#networkForm');
  var $error_fields = $form.find('input.error');
  if ($error_fields.length > 0) {
    $error_fields.first().focus();
    return false;
  }
  return true;
}

// Set #type value
$(function(){
  $('fieldset.iselector').on("click", function(){
    $('fieldset.iselector').removeClass("active");
    $(this).addClass("active");
    $("#type").val($(this).data("type"));
  });
})

// Set #interface value
$(function() {
  $("#interface_number").change(function(){
    var iface =  $("#interface_type").val() + $(this).find('option:selected').val();
    $("#interface").val(iface);
  })
})

// Toggle value of "Change hostname by DHCP" field
$(function() {
  $('#dhcp_hostname').click(function(){
    var $dhcp_hostname_enabled = $('#dhcp_hostname_enabled');
    if($(this).is(':checked')) {
      $(this).val(1);
//      $dhcp_hostname_enabled.val(true)
//      $(this).attr('checked','checked')
    } else {
      $(this).val(0);
//      $dhcp_hostname_enabled.val(false)
//      $(this).removeAttr('checked')
    }
  })
})

// Switch between configuration mods
$(function(){
  $dns_conf = $('#dns-conf');
  $ip_conf = $('#ip-conf');

  $disabled = $('#networkForm div.static input');
  $dhcp = $('#dns-conf div.dhcp');

  $('#modeSwitcher a').on('click', function() {
    var $modes = $('#modeSwitcher a');
    var mode = $(this).html().toLowerCase();

    $('#bootproto').val(mode);
    $modes.removeClass("on");
    $(this).addClass("on");

    if(mode == "none") {

      $dns_conf.hide();
      $ip_conf.hide();

    } else if(mode == "dhcp") {

      $dhcp.addClass('hidden');
      $disabled.attr('disabled', 'disabled');

      $dns_conf.show();
      $ip_conf.hide();
    } else {

      $dhcp.removeClass('hidden');
      $disabled.removeAttr('disabled');

      $dns_conf.show();
      $ip_conf.show();
    }
    return false;
  });
});
