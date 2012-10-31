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


module ApplicationHelper
  def current_url(extra_params={})
    url_for params.merge(extra_params)
  end

  # Generate the Save button and a Cancel link, with the common UI style.
  # If the form is used in a wizard, they are named Next and Back.
  # send_options applies to the submission button.
  #
  # Example:
  #   <%= form_send_buttons :disabled => write_disabled %>
  def form_send_buttons (send_options={})
    ret =  form_next_button(send_options)
    ret << form_str_spacer << form_cancel_button unless Basesystem.new.load_from_session(session).first_step?
    ret
  end

  # query if basesystem is in process
  def basesystem_in_process?
    Basesystem.new.load_from_session(session).in_process?
  end

  def form_str_spacer
    _(' or ')
  end

  def header_spacer
    _(' - ')
  end

  ##
  # Generate a cancel link with common UI style.
  # links to /controlpanel by default, developer can override
  # @param [Hash] options options for a link_to Rails helper method
  # @return [String] html part representing a cancel
  def form_back_button (options={}, html_options = {:class=>"action-link"})
    form_label_back_button _("Back"), options, html_options
  end

  def form_cancel_button (options={}, html_options = {:class=>"action-link"})
    form_label_back_button _("Cancel"), options, html_options
  end

  def form_label_back_button( label, options = {}, html_options = {:class=>"action-link"})
    if Basesystem.new.load_from_session(session).completed?
       if ! (options[:action] || options[:controller]) then
           options[:controller] = "controlpanel"
       end
       link_to label, options, html_options
    else
      link_to _("Back"), {:controller => "controlpanel", :action => "backstep"}, :class=>"action-link"
    end
  end

  def form_next_button(send_options={})
    label = send_options[:label] || _("Save")
    bs = Basesystem.new.load_from_session(session)
    label = _("Next") unless bs.completed?
    label = _("Finish") if bs.last_step?
    submit_tag label,send_options
  end

  ##
  # This helper method displays Next/Back links
  # It is similar to form_send_buttons but it uses plain links,
  # the save step is not performed
  def base_setup_links
    return form_back_button unless basesystem_in_process?

    bs = Basesystem.new.load_from_session(session)
    ret = link_to bs.last_step? ? _("Finish") : _("Next"), {:controller => "controlpanel", :action => "nextstep"}, :class => "button"

    unless bs.first_step?
      ret << form_str_spacer
      ret << (link_to _("Back"), {:controller => "controlpanel", :action => "backstep"}, :class => "action-link")
    end

    ret
  end

  # Renders an inline help (a question mark icon which displays the provided text on clicking the icon)
  #
  # @param [String] text the help text, it can include HTML tags (use html_safe to avoid escaping, not needed for translated text)
  # @param [Hash] box_options optional HTML options for the rendered help text box (e.g. {:font-color => "red"})
  # @param [Hash] icon_options optional HTML options for the rendered question mark icon (e.g. {:style => "margin-top: 20px"})
  # @return [String] rendered HTML fragment
  def help_text text, box_options = {}, icon_options = {}
    ret = image_tag 'question-mark.png', {:class => 'help_icon'}.merge(icon_options)
    ret << content_tag(:div, text, {:class => 'help_box'}.merge(box_options))
    ret
  end

end

