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

//TODO: no css overlay in Chromium 

//preload the wait.gif 
var myPic = new Image();
myPic.src = "/images/wait.gif";
         
// use this function to block form        
function blockForm(form, message) {
  $.blockUI.defaults.message = "<p><h1 id='message'>" + message + " ... <img id='waitAnimation' style='vertical-align:middle' src='/images/wait.gif'/></h1></p>";
  // fix - enable transparent overlay on FF/Linux 
  $.blockUI.defaults.applyPlatformOpacityRules = false;
    $('#'+form).block({
	showOverlay: true, 
	css: { 
	  padding:        0, 
	  margin:         0, 
	  width:          '30%', 
	  top:            '40%', 
	  left:           '35%', 
	  textAlign:      'center', 
	  color:          '#3399cc', 
	  border:         '5px solid #aaa', 
	  backgroundColor:'#fff', 
	  cursor:         'wait',
	  '-webkit-border-radius': '5px', 
          '-moz-border-radius': '5px'
	}
    });          
}

// use this function to block the whole UI window
function disableFormOnSubmit(message) {
  $.blockUI.defaults.message = "<p><h1 id='message'>" + message + " ... <img id='waitAnimation' style='vertical-align:middle' src='/images/wait.gif'/></h1></p>";
  // fix - enable transparent overlay on FF/Linux 
  $.blockUI.defaults.applyPlatformOpacityRules = false;

    $.blockUI({
	showOverlay: true, 
	css: { 
	  padding:        0, 
	  margin:         0, 
	  width:          '30%', 
	  top:            '40%', 
	  left:           '35%', 
	  textAlign:      'center', 
	  color:          '#3399cc', 
	  border:         '5px solid #aaa', 
	  backgroundColor:'#fff', 
	  cursor:         'wait',
	  '-webkit-border-radius': '5px', 
          '-moz-border-radius': '5px'
	}
    });          
}

function pleaseWaitForUpdates(message) {
  $.blockUI.defaults.message = "<p><h1 id='message'><img id='waitAnimation' style='height:32px; width:32px; margin-right:20px; vertical-align:middle' src='/images/loading.gif'/>" + message + " ...</h1></p>";
  // fix - enable transparent overlay on FF/Linux 
  $.blockUI.defaults.applyPlatformOpacityRules = false;

  $.blockUI({
    showOverlay: true, 
    css: { 
      padding:                    0, 
      margin:                     0, 
      width:                      '100%', 
      top:                        '0%', 
      left:                       '0%', 
      textAlign:                  'center', 
      color:                      '#444444', 
      border:                     '0px solid #666', 
      backgroundColor:            '#f5f5f5', 
      cursor:                     'wait'
    }
  });
}

