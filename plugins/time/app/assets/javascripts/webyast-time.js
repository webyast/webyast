/*#--
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
 #++ */

function update_time_fields()
{
  if ($("#time_set_time").is(":checked") && $("#time_set_time").attr("disabled") != "disbaled")
  {
    $("#date_date").removeAttr("disabled");
    $("#currenttime").removeAttr("disabled");
  }
  else
  {
    $("#date_date").attr("disabled","disabled");
    $("#currenttime").attr("disabled","disabled");
  }
}

function submitTime() {
  if($("#timeForm").valid() ) {
    disable_forms();
    return true;
  }

  return false;
}

$(document).ready(function() {
  $("#date_date").datepicker({
    dateFormat: 'dd/mm/yy'
  });

  $("#ui-datepicker-div").hide(); // hide a strange box created by datepicker

  if ($('#timeconfig_manual').is(":checked")) {
    $("#time_set_time").removeAttr("disabled");
  }
  else {
    $("#time_set_time").attr("disabled","disabled");
  }

  update_time_fields();
  $("#time_set_time").click(update_time_fields);

  $("#timeconfig_manual").click(enable);
  $("#ntp_sync").click(function(){
    $("#date_date")[0].disabled = true;
    $("#currenttime")[0].disabled = true;
  });

  $("#timeForm").submit(submitTime);
});

