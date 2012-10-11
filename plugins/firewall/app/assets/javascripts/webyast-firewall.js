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

//TRACK THE FORM CHANGES
var formChanged = false;

function initChagesTrack(message) {
  $("#on").click(formWasChanged);
  $("#off").click(formWasChanged);

  $('#firewallForm .firewall-service').click(formWasChanged);

   $("#firewall-wrapper .action-link").click(function(event) {
     event.stopPropagation();
     event.preventDefault();

     if (formChanged == true) {
       $.modalDialog.dialog({message:message, form: 'firewallForm'});
     } else {
      document.location = event.target.href;
     }
   });
}

function formWasChanged() {
  formChanged = true;
  $('#firewallForm .firewall-service').unbind('click', formWasChanged);
}

jQuery(function($){
  //SORT SERVICES LIST
  var $list = $('#allowed_services>span');
  $list.css('display', 'inline-block');

  var array = new Array();
  $list = $list.tsort()

  $.each($list, function(i, l){
    if (jQuery.inArray($(l).text().substr(0, 1).toLowerCase(), array) == -1) {
      array.push($(l).text().substr(0, 1).toLowerCase())
    }
  });

  var category = -1;
  var lastElement = -1;

  $.each($list, function(i, elem){
    var firstChar = $(elem).text().substr(0, 1).toLowerCase();

    if(array.indexOf(firstChar) != category) {
      $(elem).wrap('<p>').before('<b class="firstChar">' + $(elem).text().substr(0, 1) + '</b>');
      lastElement = i;
      category = array.indexOf(firstChar)
    } else {
      $($(elem)).insertAfter($list[lastElement]);
    }
  });

  var $list = $("#blocked_services>span");
  $list.css('display', 'inline-block');

  var array = new Array();
  $list = $list.tsort()

  $.each($list, function(i, l){
    if (jQuery.inArray($(l).text().substr(0, 1).toLowerCase(), array) == -1) {
      array.push($(l).text().substr(0, 1).toLowerCase())
    }
  });

  var category = -1;
  var lastElement = -1;

  $.each($list, function(i, elem){
    var firstChar = $(elem).text().substr(0, 1).toLowerCase();

    if(array.indexOf(firstChar) != category) {
      $(elem).wrap('<p>').before('<b class="firstChar">' + $(elem).text().substr(0, 1) + '</b>');
      lastElement = i;
      category = array.indexOf(firstChar)
    } else {
      $($(elem)).insertAfter($list[lastElement]);
    }
  });
});

function enableFirewallForm() {
  $('span.firewall-service')
    .removeClass('firewall_disabled')
    .addClass('firewallForm_enabled')
    .tipsy({gravity: 's', delayIn: 500});

  $('#allowed_services span.firewall-service').click(function() {
      $(this).fadeOut(200);
      $("#fw_services_values input."+$(this).attr("value")).attr("value", "false");
      $("#blocked_services span[value='"+$(this).attr("value")+"']").fadeIn(50).effect("highlight", {color:'#ff6440'}, 300);
  });

  $('#blocked_services span.firewall-service').click(function() {
      $(this).fadeOut(200);
      $("#fw_services_values input."+$(this).attr("value")).attr("value", "true");
      $("#allowed_services span[value='"+$(this).attr("value")+"']").fadeIn(50).effect("highlight", {color:'#8cb219'}, 300);
  });
}

function disableFirewallForm() {
  $('span.firewall-service')
    .removeClass('firewallForm_enabled')
    .addClass('firewall_disabled')
    .unbind('click mouseenter mouseleave');
}

// RADIO BUTTONS SWITCHER
$(document).ready(function(){
  var $on = $('#on');
  var $off = $('#off');

  function toggleMode(event) {
    event.preventDefault();

    if($(this).val() == "on") {
      $on.addClass('active');
      $('#firewall_use_firewall').val("true");
      $off.removeClass('active');

      $('#allowed_services').removeClass('firewallForm_disabled');
      $('#blocked_services').removeClass('firewallForm_disabled');

      enableFirewallForm();
    } else {
      $off.addClass('active');
      $('#firewall_use_firewall').val("false");
      $on.removeClass('active');

      $('#allowed_services').addClass('firewallForm_disabled');
      $('#blocked_services').addClass('firewallForm_disabled');

      disableFirewallForm();
    }

    $('#use_firewall').click();

    return false;
  }

  $on.click(toggleMode);

  $off.click(toggleMode);
});

