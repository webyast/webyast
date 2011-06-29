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

var protocol = "(http|https|ftp)";

var host = "([a-zA-Z0-9](([\\.\\-]?[a-zA-Z0-9]+){0,61}[a-zA-Z0-9]))+[a-zA-Z0-9]*";

var fqdn = "([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}";
var port ="(:[0-9]{1,5}|)";

var ipv4 = "^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])$";
var ipv6 = "(^(([0-9A-Fa-f]{1,4}(((:[0-9A-Fa-f]{1,4}){5}::[0-9A-Fa-f]{1,4})|((:[0-9A-Fa-f]{1,4}){4}::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,1})|((:[0-9A-Fa-f]{1,4}){3}::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,2})|((:[0-9A-Fa-f]{1,4}){2}::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,3})|(:[0-9A-Fa-f]{1,4}::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,4})|(::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,5})|(:[0-9A-Fa-f]{1,4}){7}))$|^(::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,6})$)|^::$)|^((([0-9A-Fa-f]{1,4}(((:[0-9A-Fa-f]{1,4}){3}::([0-9A-Fa-f]{1,4}){1})|((:[0-9A-Fa-f]{1,4}){2}::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,1})|((:[0-9A-Fa-f]{1,4}){1}::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,2})|(::[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,3})|((:[0-9A-Fa-f]{1,4}){0,5})))|([:]{2}[0-9A-Fa-f]{1,4}(:[0-9A-Fa-f]{1,4}){0,4})):|::)((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{0,2})\\.){3}(25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{0,2})$$";

var mail = "[A-Za-z0-9](([\\_\\.\\-]?[a-zA-Z0-9]+)*)";

var subnetmask = "^\/([12]?[0-9]|3[0-2])$";
var default_route = "^(0\\.0\\.0\\.0)$";

var time = "^(([0-1][0-9])|([2][0-3])):([0-5][0-9]):([0-5][0-9])$";
var date = "^[0,1]?\d{1}\/(([0-2]?\d{1})|([3][0,1]{1}))\/(([1]{1}[9]{1}[9]{1}\d{1})|([2-9]{1}\d{3}))$";

function getElementsByClass(searchClass, domNode, tagName) {
  var elements = [];
  var parent = document.getElementById(domNode);

  var tags = parent.getElementsByTagName(tagName);
  var tcl = " "+searchClass+" ";
  for(i=0,j=0; i<tags.length; i++) {
    var test = " " + tags[i].className + " ";
    if (test.indexOf(tcl) != -1) { elements[j++] = tags[i]; }
  }
  return elements;
}

function validateDomainName(domain) {
  jQuery.validator.addMethod(domain, function(value, element) {
    var regExp = new RegExp("^"+fqdn+"$");
    var ip4 = new RegExp(ipv4);
    var ip6 = new RegExp(ipv6);
    return this.optional(element) || regExp.test(value) || ip4.test(value) || ip6.test(value);
  });
}

// Search domains validation (bnc#607103) - accept several domain names separated through whitespace
// new RegExp("^"+host+"$") replaced through -> new RegExp("^(" + host + ")(\\ "+ host +")*$");

function validateDomainNameWithAndWithoutTLD(domain) {
  jQuery.validator.addMethod(domain,function(value,element){
    var regExp=new RegExp("^("+host+")(\\ "+host+")*$");
    return this.optional(element)||regExp.test(value);
  });
}

function validateDomainNameWithPortNumber(domain) {
  jQuery.validator.addMethod(domain, function(value, element) {
    var regExp = new RegExp("^"+fqdn+port+"$");
    var ip4 = new RegExp(ipv4);
    var ip6 = new RegExp(ipv6);
    return this.optional(element) || regExp.test(value) || ip4.test(value) || ip6.test(value);
  });
}

function validateIPv4(ip) {
  jQuery.validator.addMethod(ip, function(value, element) {
    var ip4 = new RegExp(ipv4);
    return this.optional(element) || ip4.test(value);
  });
}

// Name servers field should accept several ip separated through whitespace
function validateNameservers(ip) {
  jQuery.validator.addMethod(ip, function(value, element) {
    var ip = "(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])";
    var regExp = new RegExp("^("+ip+")(\\ "+ip+")*$");
    return this.optional(element) || regExp.test(value);
  });
}


function validateSubnetMask(netmask) {
  jQuery.validator.addMethod(netmask, function(value, element) {
    var ip4 = new RegExp(ipv4);
    var smask = new RegExp(subnetmask); 
    return this.optional(element) || ip4.test(value)  || smask.test(value);
  });
}

function validateDefaultRoute(ip) {
  jQuery.validator.addMethod(ip, function(value, element) {
    var ip4 = new RegExp(ipv4);
    var def_route = new RegExp(default_route);
    return this.optional(element) || ip4.test(value) || def_route.test(value);
  });
}


//Devel build 9.32 has messed networking configuration in webyast (bnc#694283)
//RFC-952 and RFC-1123.
var rfc = "([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])*";

function validateHostName(hostname) {
  jQuery.validator.addMethod(hostname, function(value, element) {
    var regExp = new RegExp("^"+rfc+"$");
    return this.optional(element) || regExp.test(value); 
  });
}

function validateURL(url) {
  jQuery.validator.addMethod(url, function(value, element) {
    var regExp = new RegExp("^"+protocol+"://"+fqdn+"$");
    return this.optional(element) || regExp.test(value);
  });
}

function validateEmail(email)
{
  jQuery.validator.addMethod(email, function(value, element) {
    var regExp = new RegExp("^"+mail+"@"+fqdn+"$");
    return this.optional(element) || regExp.test(value);
  });
}

function validateTime(ctime) {
  jQuery.validator.addMethod(ctime, function(value, element) {
    var regExp = new RegExp(time);
    return this.optional(element) || regExp.test(value);
  });
}

function validateDate(cdate) {
  jQuery.validator.addMethod(cdate, function(value, element) {
    var regExp = new RegExp(date);
    return this.optional(element) || regExp.test(value);
  });
}
