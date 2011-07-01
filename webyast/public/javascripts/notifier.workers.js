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

function XHRrequest(module, id, auth_token) {
  var xhr = new XMLHttpRequest();
  
  self.module = module;
  self.auth_token = auth_token;
  
  if(typeof id !== 'undefined') { 
    self.id = id;
    var url = '/notifier?plugin='+self.module+'&id='+self.id; 
  } else {
    var url = '/notifier?plugin='+self.module;
  }
  
  if(xhr) {    
    xhr.open('get', url);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.send(self.auth_token);
    
    xhr.onreadystatechange = function() {
      if(xhr.readyState == 4) {
	if (xhr.status == 200) {
	  postMessage(xhr.responseText);
	  if(self.id !='#') {
	    setTimeout(XHRrequest, 5000, self.module, self.id, self.auth_token);
	  } else {
	    setTimeout(XHRrequest, 5000, self.module, self.auth_token);
	  }
	} else {
	  postMessage(xhr.status);
	  self.close();
	}
      }
    }
  }
}

onmessage = function(event) {
  var target = event.data;
  XHRrequest(target.module, target.id, target.AUTH_TOKEN);
}
