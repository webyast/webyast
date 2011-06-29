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

function sessionTimeout(currentTime, expirationDate) {
  // Don't start the timer if user is logged out
  var logout_path =  window.location.protocol + "//" + window.location.host + "/logout";
  var loged_out = String(window.location.protocol + "//" + window.location.host + "/session/");
  var current_location = String(window.location);

  var expiresIn = expirationDate-currentTime;

  //DEBUG
  //expiresIn  = 305 //just for test
  //var logContainer = jQuery("div.time_left");
  //<END>

  //console.log(expirationDate - currentTime)

  expiresIn = expiresIn-35; // show warning message 5 minutes before the session expires

  // check current location and start timer if user is logged on
  if(current_location.match(loged_out) == null) {
    jQuery.fjTimer({
      interval: 1000,
      repeat: expiresIn,
      tick: function(counter, timerId) {
	  //DEBUG
	  //timeLeft = (expiresIn - (counter+1));
	  //$("div.timer_logpanel").text("Expire in "+ timeLeft + "Time zone " + tzo);
	  //$("div.time_left").text("Expire in "+ timeLeft);
	  //console.log(timeLeft);
	  //<END>

      },
      onComplete: function() {
	$("#timeoutMessage").slideDown(); // show the warning bar

	messageTimeout = 30;

	jQuery.fjTimer({
	  interval: 1000,
	  repeat: messageTimeout,
	  tick: function(counter, timerId) {
	    $("#counter").text(" " + (messageTimeout-counter) + " ");
	  },
	  onComplete: function() {
	    $("#timeoutMessage").slideUp(); // show the warning bar
	    location = logout_path; // redirect to logout page and stop all counters
	  }
	});
      }
    });
  }
}

