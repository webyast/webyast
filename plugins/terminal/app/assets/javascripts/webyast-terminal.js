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

$(document).ready(function(){
  // display shellinabox service running at port 4200 on the same machine
  $("#term_iframe").attr("src", "https://" + window.location.hostname + ":4200");
  $("#new_window").attr("href", "https://" + window.location.hostname + ":4200");

  $("#fullscreen").click(function(){
    $(".webyast_fieldset").css("position", "static");
    $("#frameBorder").addClass("fullscreen");
    $("#closeFullscreen").fadeIn('slow');
  });

  $("#closeFullscreen").click(function(){
    $(".webyast_fieldset").css("position", "relative");
    $("#frameBorder").removeClass("fullscreen");
    $("#closeFullscreen").hide();
  });
});

