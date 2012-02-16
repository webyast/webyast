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

$(function(){
//  var $auto = $('#autoMode');
//  var $manual = $('#manualMode');

//  //bootproto attribute values (static | dhcp4 | dhcp6)
////  $("#conf_mode").val().match("dhcp")? enableAuto(): enableStatic();

//  $("#bootproto").val().match("dhcp")? enableAuto(): enableStatic();

//  function enableAuto() {
//    $('#dnsForm').find('div.auto').hide();
//    $('#ip-container').hide();
//    $('#ip_sticker').show();
//    $('div.auto input').attr('disabled', 'disabled');
//  }

//  function enableStatic() {
//    $('div.auto input').removeAttr('disabled');
//    $('#ip-container').show();
//    $('#ip_sticker').hide();
//    $('#dnsForm').find('div.auto').show();
//  }

//  function toggleMode($id) {
//    if($id.val() == "dhcp") {
//      $auto.addClass('active');
//      $manual.removeClass('active');
//      $('#conf_mode').val($auto.val());
//      enableAuto();
//    } else {
//      $manual.addClass('active');
//      $auto.removeClass('active');
//      $('#bootproto').val($manual.val());
//      enableStatic()
//    }
//  }

//  $auto.click(function(event) {
//    event.preventDefault();
//    toggleMode($(this));
//    return false;
//  });

//  $manual.click(function(event) {
//    event.preventDefault();
//    toggleMode($(this));
//    return false;
//  });
})


//function submitValidForm() {
//  if($('#dnsForm').find('input.error').length >0)
//  return true;
//}

function is_valid() {
  var $form = $('#networkForm');
  var $error_fields = $form.find('input.error');
  if ($error_fields.length > 0) {
    $error_fields.first().focus();
    return false;
  }
  return true;
}

//function disableForm($form) {
//  $form.css('background-color', '#f2f2f2').css('color', '#888').find('input').attr('disabled', 'disabled').css('background', '#f2f2f2');
//}

//function enableForm($form) {
//  $form.css('background-color', '#fff').css('color', '#333').find('input').removeAttr('disabled').css('background', '#fff');
//}



$(function(){
  // Get next available interface number and render partial according to interface type
  $('select#interface_type').change(function(){
    console.log($(this).find('option:selected').val())
    var type = $(this).find('option:selected').val();
    $("#ajax_call").toggle();
    $.getJSON('/network/iface', "type="+type, function(response) {
        $("#interface").val(response[0])

        var options = new Array
        $.each(response, function(key, value) {
          options.push('<option value="'+ value +'">'+ value +'</option>');
        });

        console.log(options)
        $('select#interface_name').html("")
        $('select#interface_name').html(options.join(''));
        $("#ajax_call").toggle();

          $.get('partial', "partial="+type, function(data) {
            $('#interface_fields').html(data).show();
          });
      }
    );
  });
});


$(function(){
  // Toggle value of "Change hostname by DHCP" field
  $('#dhcp_hostname').click(function(){
    var $dhcp_hostname_enabled = $('#dhcp_hostname_enabled');
    if($(this).is(':checked')) {
      $dhcp_hostname_enabled.val(true)
      $(this).attr('checked','checked')
    } else {
      $dhcp_hostname_enabled.val(false)
      $(this).removeAttr('checked')
    }
  })

  // Switch between configuration mods
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


// $(document).ready(function(){
//   $dns = $('#dns-container');
//   $ip = $('#ip-container');
//
//   $dns.bind('click', function(){
//     console.log("DNS clicked")
//     if(validateForm($ip) == true) {
//       $(this).css('width', '58%').css('font-size', '12px').find('div.row label').css('width','160px');
//       $ip.css('width', '38%').css('font-size', '10px');
//       $ip.find('div.row label').css('width','100px');
//     }
//     return false;
//   });
//
//   $ip.bind('click', function(){
//     console.log("IP clicked")
//     if(validateForm($dns) == true) {
//       $(this).css('width', '58%').css('font-size', '12px').find('div.row label').css('width','160px');
//       $dns.css('width', '38%').css('font-size', '10px');
//       $dns.find('div.row label').css('width','100px');
//     }
//     return false;
//   });
// });
