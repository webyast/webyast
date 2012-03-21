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

var timer = 0;
function notification(params, interval, inactive) {
  timer = window.setInterval(function() { Notify(params); },5000);
}

function pageRefresh() { location.reload(); }

function Notify(params) {
  $.ajax({
    url: "/notifier?plugin=" + params.module,
    statusCode: {
      200:function() { 
        var message = "Data has been changed";
        $.modalDialog.info({ message: message});
        setTimeout('pageRefresh()', 1000);
      },
      
      306:function() { 
        console.info("cache is disabled"); 
        window.clearInterval(timer);
      },
      
      404:function() { 
        window.clearInterval(timer);
      },
      
      422:function() { 
        window.clearInterval(timer);
      },
      
      500:function() { 
        window.clearInterval(timer); 
      }
    }
  });
}
