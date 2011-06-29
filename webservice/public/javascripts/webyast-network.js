/*
#--
# Webyast Webservice framework
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
  var $dhcp_hostname = $('#dhcp_hostname');
  $dhcp_hostname.click(function(){
    if($dhcp_hostname.is(':checked')) {
      $dhcp_hostname.attr('checked','checked')
    } else {
      $dhcp_hostname.removeAttr('checked')
    }
  })
  
  var $auto = $('#autoMode');
  var $manual = $('#manualMode');
      
  $("#conf_mode").val() == "dhcp"? enableAuto(): enableStatic();
  
  function enableAuto() {
    $('#dnsForm').find('div.auto').hide();
    $('#ip-container').hide();
    $('#ip_sticker').show();
    $('div.auto input').attr('disabled', 'disabled');
  }
  
  function enableStatic() {
    $('div.auto input').removeAttr('disabled');
    $('#ip-container').show();
    $('#ip_sticker').hide();
    $('#dnsForm').find('div.auto').show();
  }
  
  function toggleMode($id) {
    if($id.val() == "dhcp") {
      $auto.addClass('active');
      $manual.removeClass('active');
      $('#conf_mode').val($auto.val());
      enableAuto();
    } else {
      $manual.addClass('active');
      $auto.removeClass('active');
      $('#conf_mode').val($manual.val());
      enableStatic()
    }
  }

  $auto.click(function(event) {
    event.preventDefault();
    toggleMode($(this));
    return false;
  });
  
  $manual.click(function(event) {
    event.preventDefault();
    toggleMode($(this));
    return false;
  });
})


function submitValidForm() {
  if($('#dnsForm').find('input.error').length >0) $('#dnsForm').find('input.error').first().focus();
  return true;
}
  
function validateForm($form) {
  var valid = false;
  var count = $form.find('input.error').length;
  count == 0? valid = true : valid = false;
  return valid;
}

function disableForm($form) {
  $form.css('background-color', '#f2f2f2').css('color', '#888').find('input').attr('disabled', 'disabled').css('background', '#f2f2f2');
}

function enableForm($form) {
  $form.css('background-color', '#fff').css('color', '#333').find('input').removeAttr('disabled').css('background', '#fff');
}




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

