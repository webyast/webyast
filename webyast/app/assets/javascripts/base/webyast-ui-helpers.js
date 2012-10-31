/*
Copyright (C) 2012 Novell, Inc.

All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of version 2 of the GNU General Public License
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, contact Novell, Inc.

To contact Novell about this file by physical or electronic mail,
you may find current contact information at www.novell.com
*/

$(document).ready(function() {
  var tipsy_config = {gravity: 's', delayIn: 500, delayOut: 500, fade: true};
  $(".tipsy_help").tipsy(tipsy_config);

  tipsy_config.html = true;
  $(".tipsy_help_html").tipsy(tipsy_config);
});

