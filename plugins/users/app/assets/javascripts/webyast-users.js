/*
# Copyright (c) 2009-2010 Novell, Inc.
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
*/

// GLOBAL FIXME: use jQuery properly in this file, avoid plain JS (e.g. [0])

// using replace instead of trim() see bnc#580561
function _trim(word){
  return word.replace(/^\s*|\s*$/g,'');
}

// WTF? FIXME: use standard jQuery selectors for this!
function _getElementsByClassName(node, classname)  {
    if(!node) node = document.getElementsByTagName("body")[0];
    var a = [];
    var re = new RegExp('\\b' + classname + '\\b');
    var els = node.getElementsByTagName("*");
    for(var i=0,j=els.length; i<j; i++)
        if(re.test(els[i].className))a.push(els[i]);
    return a;
}

// onsubmit handler
// FIXME: "message" parameter is not used
 function form_handler(sid, message) {
   return $('#form_' + sid).valid();
 }

// delete button handler
// FIXME: "progress" parameter is not used
function delete_handler(which, progress, message){
 if (which.childElementCount == 2 && which.children[0].firstChild.textContent == "Delete"){
  which.childNodes[0].onclick="return false;";
  which.childNodes[0].href="";

  disableFormOnSubmit(message);
 }
}

function arrays_complement(a1,a2){
 var a3 = [];
 for(var i=0;i<a1.length;i++){
  var found=false;
  for(var j=0;j<a2.length;j++){
   if (a1[i]==_trim(a2[j])) found=true;
  }
  if (!found) a3.push(a1[i]);
 }
 return a3;
}

function members_validation(which){
  var mygroups = [];
  if (_trim(which.value).length>0) mygroups = which.value.split(",");
  var allgroups = $("#all_users_string").val().split(",");
  allgroups=allgroups.concat($("#system_users_string").val().split(","));
  errmsg="";
  for (i=0;i<mygroups.length;i++){
    var found=false;
    for(a=0;a<allgroups.length;a++){
     if (allgroups[a]==_trim(mygroups[i])) found=true;
    }
    if (!found){
     errmsg = mygroups[i]+" "+"is not valid user!" ;
    }
  }
  _getElementsByClassName(which.parentNode.parentNode, 'error')[0].innerHTML = errmsg;
  _getElementsByClassName(which.parentNode.parentNode, 'error')[0].style.display= (errmsg.length==0) ? "none" : "block";
  return (errmsg.length==0);
}


function set_tab_focus(tab){
  $("#accordion").accordion('activate',$("#tab_"+tab).children("legend"));
}


function findById(where, id){
 var node=null;
 for(var i=0;i<where.length;i++){
  if (where[i].id==id) node=where[i];
 }
 return node;
}


function groups_validation(which){
  var mygroups = _trim(findById(which.parentNode.getElementsByTagName('input'), "user_grp_string").value);
  if (mygroups.length>0) mygroups = mygroups.split(",");
  var allgroups = $("#all_grps_string").val().split(",");
  errmsg="";
  for (i=0;i<mygroups.length;i++){
    var found=false;
    for(a=0;a<allgroups.length;a++){
     if (allgroups[a]==_trim(mygroups[i])) found=true;
    }
    if (!found){
     errmsg = mygroups[i]+" "+"is not valid group!" ;
    }
  }
  set_tab_focus("groups")
  // WTF? FIXME: use jQuery here!
  var error = findById(which.parentNode.parentNode.parentNode.getElementsByTagName('label'), "groups-error");
  error.innerHTML = errmsg;
  error.style.display= (errmsg.length==0) ? "none" : "block";
  return (errmsg.length==0);
}

function def_group_validation(which){
  var mygroup = _trim(findById(which.parentNode.getElementsByTagName('input'), "user_groupname").value);
  var allgroups = $("#all_grps_string").val().split(",");
  errmsg="";

   if (mygroup.length>0){
    var found=false;
    for(a=0;a<allgroups.length;a++){
     if (allgroups[a]==_trim(mygroup)) found=true;
    }
    if (!found){
     // FIXME: make this translatable
     errmsg = mygroup+" "+"is not valid group!" ;
    }
   }

  set_tab_focus("groups")
  // WTF? FIXME: use jQuery here!
  var error = findById(which.parentNode.parentNode.parentNode.getElementsByTagName('label'), "def-group-error");
  error.innerHTML = errmsg;
  error.style.display= (errmsg.length==0) ? "none" : "block";
  return (errmsg.length==0);
}

function roles_validation(which){
  // WTF? FIXME: use jQuery here!
  var myroles = _trim(findById(which.parentNode.getElementsByTagName('input'), "user_roles_string").value);
  if (myroles.length>0) myroles = myroles.split(",");
  var allroles = $("#all_roles_string")[0].value.split(",");
  errmsg="";
  for (i=0;i<myroles.length;i++){
    var found=false;
    for(a=0;a<allroles.length;a++){
     if (allroles[a]==_trim(myroles[i])) found=true;
    }
    if (!found){
     // FIXME: make this translatable
     errmsg = myroles[i]+" "+"is not valid role!" ;
    }
  }
  set_tab_focus("roles")
  // WTF? FIXME: use jQuery here!
  var error = findById(which.parentNode.parentNode.parentNode.getElementsByTagName('label'), "roles-error");
  error.innerHTML = errmsg;
  error.style.display= (errmsg.length==0) ? "none" : "block";
  return (errmsg.length==0);
}

function user_exists_validation(el){
  var valid = true;
  var this_user = el.value;
  // TODO FIXME: use native JS list (via Array.to_json from Ruby), avoid $("#all_users_string").val().split(",")
  var users_list = $("#all_users_string").val() == "" ? [] : $("#all_users_string").val().split(",");

  $.each(users_list, function() {
    if(this == this_user) {
      valid = false;
      return valid;
    }
  });

  $("#user_name-error").toggle(!valid);

  return valid;
}

// FIXME: "which" parameter is not used at all
function user_validation(which, username){
  var valid = true;
  var form = '#form_'+username;
  // for new users test if already not exists
  if (username == ""){
   valid = user_exists_validation();
   if (!valid) $(".tabs_").tabs('select',"#tab_login_");
  }

  if (valid && ($(form).validate().element(form+' #user_uid')==false || $(form).validate().element(form+' #user_user_password')==false || $(form).validate().element(form+' #user_user_password2')==false)){
	$(".tabs_"+username).tabs('select',"#tab_login_"+username);
	valid = false;
  }
  if (valid && (groups_validation($(form+' #user_grp_string')[0])==false || def_group_validation($(form+' #user_groupname')[0])==false)){
	$(".tabs_"+username).tabs('select',"#tab_groups_"+username);
	valid = false;
  }
  if (valid && $(form).validate().element(form+' #user_uid_number')==false){
	$(".tabs_"+username).tabs('select',"#tab_advanced_"+username);
	valid = false;
  }

  return valid;

}


function propose_home(login){
  // FIXME: fix this strange argument checking and overriding
  if(arguments.length == 0) {
    var login = $("#user_uid").val();
  }
  $("#user_home_directory").val("/home/" + login);
}

function propose_login(){
  var fullname = $("#user_cn").val();
  var login    = $("#user_uid").val();
  if (login.length==0){
    login = fullname.replace(/\s/g, '').toLowerCase();
    propose_home(login);
  }
}

function check_uniq_uid_number() {
  var existing_uid_nums = $("#all_uid_numbers_string").val().split(',');
  var new_uid_num       = $("#user_uid_number").val();
  var uid_num_exists    = false
  $.each(existing_uid_nums, function() {
    if(new_uid_num == this) {
      uid_num_exists = true
      return false
    }
  });

  $('#uid-error').toggle(uid_num_exists);
}

