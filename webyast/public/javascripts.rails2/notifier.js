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

var log = function(message) { 
  if (typeof(console) != 'undefined' && typeof(console.log) == 'function'){ console.log(message); } else { return false }
}

function pageRefresh() { self.location = window.location.href; }

//TODO: call twice???
function stopNotifierPlugin(worker) {
  var stop = { stop: function() { return this.timer }};
  var activityTimer = jQuery.extend($.activity, stop);

  if(activityTimer && worker) { 
    worker.terminate();
    clearInterval($.activity.stop()); 
    //log("Stop JQuery activity check & terminate running worker!")
  } 
}

function startNotifier(params, interval, inactive) {
  killWorkerOnReload(Notifier(params));

  $(document).ready(function() {
    jQuery(function($){
      $.activity.init({
        interval: interval, 
        inactive: inactive, 
        intervalFn: function(){
          //log("User is idle: " + Math.round((this.now() - this.defaults.lastActive)/1000) + ' sec');
        },
        inactiveFn: function(){
          //log("User is inactive: " + Math.round((this.now() - this.defaults.lastActive)/1000)  + ' sec');
          if(typeof(Worker) != 'defined') { killWorker(worker); }
          $.activity.update();
        }
      });
      
    $(document).bind('click mousemove', function(){
      if($.activity.isActive()) {
        $.activity.update();
      } else {
        //log("User active start worker and reactivate activity check!");
        Notifier(params);
        $.activity.reActivate();
      }
      });
    });
  })
}

var Notifier = function(params) {
  if(typeof(Worker) == 'undefined') {
    //console.log("Web worker is not supported")
    window.setInterval(function() { AJAXcall(params); },5000);
  } else {
    //console.log("Web worker is supported")
    worker = new Worker("/javascripts/notifier.workers.js");
    worker.postMessage(params);
    
    worker.onmessage = function(event) {
      switch(event.data){
        case '200':
          //log("RELOAD is NEEDED: " + event.data);
          stopNotifierPlugin(this);
          $.modalDialog.info( {message: 'Data has been changed!'});
          setTimeout('pageRefresh()', 1000)
        break
        case '304':
          //log("CACHE is UP-TO-DATE: " + event.data); 
        break
        case '306':
          //log("CACHE is not available: " + event.data); 
          stopNotifierPlugin(worker);
        break
        default : 
          //log("ERROR: unknown HTTP status: " + event.data);
          stopNotifierPlugin(worker);
        break
      }
    };

    worker.onerror = function(error) {
      //log(error);
    };

    return worker;
  }
}

var AJAXcall = function(params) {
  $.getJSON("/notifier?plugin="+params.module, function(data, status, jqXHR) {
    data.NaN? data = data : data = data.toString();
    switch(data){
      case '200':
        //log("RELOAD is NEEDED: " + data);
        stopNotifierPlugin(worker);
        $.modalDialog.info( {message: 'Data has been changed!'});
        setTimeout('pageRefresh()', 1000)
      break
      case '304':
        //log("CACHE is UP-TO-DATE: " + data); 
        break
      case '306':
        //log("CACHE is not available: " + event.data); 
        break
      default : 
        //log("ERROR: unknown HTTP status: " + data + typeof(data));
      break
    }
  })
}

var killWorker = function(worker) {
  if(worker && typeof(Worker) != 'undefined') {
     stopNotifierPlugin(worker);
  }
}

var killWorkerOnReload = function(worker, intervalID) {
  $(function(){
    window.onbeforeunload = function(){
      if(worker && typeof(Worker) != 'undefined') {
        stopNotifierPlugin(worker);
      }
    }
  });
}
