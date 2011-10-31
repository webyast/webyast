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

/* add tabs navigation needed by jquery-tabs to fieldset-groups */
function addTabsNavigation(fragment_sel_str,title_sel_str) {
  var fragments = $(fragment_sel_str).children();
  $(fragment_sel_str).prepend("<ul></ul>");
  fragments.each ( function(index,fragment) {
    var fragment_id = fragment.id;
    var fragment_title = $("#"+fragment_id).children().slice(0,1).find(title_sel_str)[0].innerHTML;
    $("#"+fragment_id).children().slice(0,1).hide();
    $(fragment_sel_str+" ul").append('<li><a href="#'+fragment_id+'"><span>'+fragment_title+'</span></a></li>');
  });
}

 // disable all submit buttons after submitting a form
 // avoid double submit by accident
 function disable_forms() {
   // disable submit buttons
   $(':submit').attr('disabled', 'disabled');
   // make all input elements (text fields...) read only
   $(':input').attr('readonly', 'readonly');
   // disable all delete buttons
   $('a.button').attr('onclick','return false;');
   $('a.button').attr('href','');
   $('a.button').attr('disabled', 'disabled');
 }

$(document).ready(function() {
  
   // Change BG Colour on mouseover and change it back on mouse out
   $('.highlight-bg').mouseover(function() {
   $(this).addClass('grey-bg'); // add class for highlighting
   }).mouseout(function() {
   $(this).removeClass('grey-bg'); // remove class for highlighting
   });

  // Alternating Lines in "Tables"
  $('.alternate-rows > li:even').addClass('alt-bg');

  // Accordion: make area expandable by clicking anywhere in the collapsed part
  $(".ui-accordion-header").parent().click( function() {
    if ($(this).is(":has(legend.ui-accordion-header.ui-state-default)")) {
      $(".accordion").accordion('activate',$(this).children(".ui-accordion-header.ui-state-default"));
    };
  });
});
