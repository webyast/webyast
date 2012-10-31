#--
# Webyast Webclient framework
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


module ViewHelpers::HtmlHelper
  # report an exception to the flash messages zone
  # a flash error message will be appended to the
  # element with id "flashes" with standard jquery
  # ui styles. A link with more information that
  # display a popup is also automatically created
  def report_error(error, message=nil)
    # get the id of the error, or use a random id
    error_id = error.nil? ? rand(10000) : error.object_id

    err_message = error.try(:message)
    err_message ||= _("Unknown error")

    # get the backtrace, or create a message saying there is none
    backtrace_text = error.try(:backtrace).try(:join, "\n")
    backtrace_text = _("No information available") if backtrace_text.blank?

    # the summary message
    message ||= _("There was a problem retrieving information from the server.")

    # build the html
    # FIXME: put this into a partial (easier editing than a heredoc)
    html =<<-EOF2
      <div id="error-#{error_id}-content">
        <div>
          <p><strong>Error message:</strong>#{err_message}</p>
          <p class="bug-icon"><a target="_blank" href="#{"FIXME ::ApplicationController.bug_url"}">Report bug</a></p>
          <p>
            <a href="#" id="error-#{error_id}-show-backtrace-link">Show details</a>
          </p>
          <pre id="error-#{error_id}-backtrace" style="display: none">
          #{backtrace_text}
          </pre>
        </div>
      </div>

      <div class="ui-state-error ui-corner-all" style="margin-top: 20px; padding: 0 .7em;" id="error-#{error_id}-summary">
        <p><span class="ui-icon ui-icon-alert"/>#{message} (<a href="#" id="error-#{error_id}-details-link">more..</a>)</p>
      </div>

      <script type="text/javascript">
        $(document).ready(
          function() {
            //$('#error-#{error_id}-summary').hide();

            // hide the exception details
            $('#error-#{error_id}-content').hide();

            // put the error summary with the other flashes
            // and not where the output should go
            $('#flash-messages').prepend($('#error-#{error_id}-summary'));

            //$('#error-#{error_id}-content').show();

           // define a dialog with the error details
           $('#error-#{error_id}-content').dialog(
           {
    	     bgiframe: true,
    	     autoOpen: false,
    	     height: 300,
    	     modal: true
           });

           // make the More link to open the dialog with details
           $('#error-#{error_id}-details-link').click( function() {
             $('#error-#{error_id}-content').dialog('open');
           });

           // make the Show details links show the backtrace
           $('#error-#{error_id}-show-backtrace-link').click(function() {
             $('#error-#{error_id}-backtrace').hide();
             $('#error-#{error_id}-backtrace').show();
             return false;
           });
         });
     </script>
EOF2
  html.html_safe
  end

  # Encode an input string to a string which can be safely used as
  # an HTML element id without escaping problematic symbols.
  # The result contains only [a-zA-Z0-9_]* characters and can be used in jQuery
  # selectors without escaping.
  # Example:
  #     my_id = safe_id id

  #     <td id="my_table_item_<%= my_id -%>" ...
  #     remote_function(:update => "#my_table_item_#{my_id}", ... )
  #     $('#my_table_item_#{my_id}').hide()
  def safe_id id
    return nil if id.nil?

    require 'base64'

    # encode using Base64 encoding, remove the padding at the end
    Base64.encode64(id.to_s).match /^([^=]*)=*$/

    # make one line string and replace symbols used in Base64
    # to get string containing only [-a-zA-Z0-9_]* characters
    # see http://en.wikipedia.org/wiki/Base64
    # (esp. "modified Base64 for URL" paragraph)
    ret = $1
    ret.gsub!("\n", '')
    ret.gsub!('+', '-')
    ret.gsub!('/', '_')
    ret
  end

  # JavaScript String, makes a JS literal from a string value,
  # typically from a translated string.
  #
  # Usage:
  #
  #   alert(<%= jss _("These are 'quotes'.") -%>);
  #
  # That works correctly if the text gets translated
  # to 'Toto jsou "uvozovky".'
  # (see also https://bugzilla.novell.com/show_bug.cgi?id=604224)
  def jss(s)
    "\"#{escape_javascript s}\"".html_safe
  end

end

# vim: ft=ruby

