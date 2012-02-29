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


$(document).ready(function() {
  console.log("GET STATUS")
  $("#services div.list-fieldset").each (function(index) {

//  console.log("GET STATUS")

  if ($(this).is(":has(span.status_running)")) {
    $(this).find(".list-fieldset-header .service-icon").attr('class','service-icon status-icon ok');

    if ($(this).is(":has(div.service_disabled)")) {
      $(this).find(".list-fieldset-header .service-icon").attr('class','service-icon status-icon ok-unused');
    }
  }

  else if ($(this).is(":has(span.status_dead)")) {
	    $(this).find(".list-fieldset-header .service-icon").attr('class','service-icon status-icon error');
	}
	else {
	    $(this).find(".list-fieldset-header .service-icon").attr('class','service-icon status-icon unused');
	    if ($(this).is(":has(div.service_enabled)")) {
		$(this).find(".list-fieldset-header .service-icon").attr('class','service-icon status-icon unused-ok');
	    }
	}
    });

    $('input#service_search').quicksearch('#services div.list-fieldset', {
      selector: '.quicksearch_content',
      delay: 100
    });

    $('.accordion div.list-fieldset:even').addClass('alt-bg');
})


// adapt the status icon of given service
function toggle_service_info (name) {

    var id	= '#service_status_' + name;
    var heading	= $(id).closest('.service-content').siblings('div.list-fieldset-header');

    if ($(id).is(':has(span.status_running)')) {
	$(heading).find(".service-icon").attr('class','service-icon status-icon ok');
	$('a#start_' + name).hide();
	$('a#stop_' + name).show();
	// running, but disabled: not ok
	if ($(id).is(':has(div.service_disabled)')) {
	    $(heading).find(".service-icon").attr('class','service-icon status-icon ok-unused');
	}
    }
    else if ($(id).is(':has(span.status_dead)')) {
	$(heading).find(".service-icon").attr('class','service-icon status-icon error');
	$('a#stop_' + name).hide();
	$('a#start_' + name).show();
    }
    else {
	$(heading).find(".service-icon").attr('class','service-icon status-icon unused');
	$('a#stop_' + name).hide();
	$('a#start_' + name).show();
	// not running, but enabled: not unused
	if ($(id).is(':has(div.service_enabled)')) {
	    $(heading).find(".service-icon").attr('class','service-icon status-icon unused-ok');
	}
    }
    // hide enable/disable buttons if they should not be seen
    // explicitely check if some status is present, custom services do not have it
    if ($(id).is(':has(div.service_disabled)')) {
	$('a#disable_' + name).hide();
	$('a#enable_' + name).show();
    } else if ($(id).is(':has(div.service_enabled)')) {
	$('a#enable_' + name).hide();
	$('a#disable_' + name).show();
    }
}

function select_status (val) {
    if (val == "all") {
	$("#services > div.list-fieldset").show();
    }
    else if (val == "not-running") {
	$('#services > div.list-fieldset').each(function(index) {
	    if ($(this).is(":has(span.status_not_running)")) {
		$(this).show();
	    } else {
		$(this).hide();
	    }
	});
    }
    else if (val == "running") {
	$('#services > div.list-fieldset').each(function(index) {
	    if ($(this).is(":has(span.status_running)")) {
		$(this).show();
	    } else {
		$(this).hide();
	    }
	});
    }
    else if (val == "dead") {
	$('#services > div.list-fieldset').each(function(index) {
	    if ($(this).is(":has(span.status_dead)")) {
		$(this).show();
	    } else {
		$(this).hide();
	    }
	});
    }
    else if (val == "enabled") {
	$('#services > div.list-fieldset').each(function(index) {
	    if ($(this).is(":has(div.service_enabled)")) {
		$(this).show();
	    } else {
		$(this).hide();
	    }
	});
    }
    else if (val == "disabled") {
	$('#services > div.list-fieldset').each(function(index) {
	    if ($(this).is(":has(div.service_disabled)")) {
		$(this).show();
	    } else {
		$(this).hide();
	    }
	});
    }
}

// hide the buttons and current state while the action is performed
function disable_buttons (s) {

    $('#service_progress_' + s).show();
    $('#service_status_' + s).hide();
    $('#service_result_' + s).hide();
    $('#service_refresh_' + s).hide();
    $('a.button').attr('disabled', 'disabled');
}

// show the results and enable buttons back
function enable_buttons (s) {
    $('#service_progress_' + s).hide();
    $('#service_status_' + s).show();
    $('#service_refresh_' + s).show();
    $('a.button').removeAttr('disabled');
}

$(document).ready(function(){
  $(".accordion").accordion({
     autoHeight : false,
     navigation : true,
     collapsible: true,
     header     : 'div.list-fieldset div.list-fieldset-header',
     change: function(event, ui) {
          $('#service_result_' + $(ui.oldHeader).attr("name")).hide();
      },
     animated   : false
  });
  $(".accordion").accordion('activate',false);

  $("#filter_services").change(function() {
    select_status($(this).val());
  });

});
