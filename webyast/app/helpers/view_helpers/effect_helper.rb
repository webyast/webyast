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

module ViewHelpers::EffectHelper
  include GetText

  # show_hide_elements - create links and JavaScript snippets to show and hide one or more HTML elements
  #   takes two parameters
  #   1. String or Symbol or Array of these both with the element ID(s) (required)
  #   2. Hash with confugiration parameters (optional)
  #      Hash keys:
  #        :hidden => <true/false>  -  is/are the element(s) initially hidden? - reverses the function
  #        :hide_msg => "str"       -  string to show for the "hide" action
  #        :show_msg => "str"       -  string to show for the "show" action
  #        :effect_opt => Hash      -  effect options, eg. {:duration => 3} for a 3 sec. effect
  #        :hide_effect => :symbol  -  effect to use for the "hide" action
  #        :show_effect => :symbol  -  effect to use for the "show" action (see jrails.rb for more SCRIPTACULOUS_EFFECTS)
  #
  #  Examples:
  #  show_hide_elements :elementid, { :hidden => true, :hide_msg => _("Hide Details"), :show_msg => _("Show Details") }
  #  show_hide_elements [:thisthing, :otherthing, "thirdthing"], { :show_effect => :bounce_in,
  #                                                                :hide_effect => :drop_out,
  #                                                                :effect_opt  => { :duration => 3 }  }
  def show_hide_elements(elm, options={})
    if    elm.kind_of?(Array) then
      elements = elm
    elsif elm.kind_of?(String) || elm.kind_of?(Symbol) then
      elements = Array.new([elm])
    else
      return "<h2 style='color: red'>No element IDs defined for show_hide_elements effect.</h2>"
    end
    options = Hash.new unless options.kind_of?(Hash)

    hidden      = !options[:hidden].nil? ? options[:hidden] : true
    hide_msg    = options[:hide_msg]    || _("Hide Details")
    show_msg    = options[:show_msg]    || _("Show Details")
    show_effect = options[:show_effect] || :switch_on
    hide_effect = options[:hide_effect] || :switch_off
    effect_opt  = options[:effect_opt]  || Hash[ :duration => 0 ]

    hide_id = "hidedetails" + elements.object_id.to_s
    show_id = "showdetails" + elements.object_id.to_s
    ret = "<p id='#{hide_id}' "
    ret += " style='display: none' " if hidden
    ret += ">"
    ret += link_to_function hide_msg do |p|
             p.visual_effect( :switch_off, hide_id, {:duration => 0} )
             p.visual_effect( :switch_on,  show_id, {:duration => 0} )
             elements.each do |e|
               p.visual_effect( hide_effect, e, effect_opt )
             end
           end
    ret += "</p>"
    ret += "<p id='#{show_id}' "
    ret += " style='display: none' " unless hidden
    ret += ">"
    ret += link_to_function show_msg do |p|
             p.visual_effect( :switch_off, show_id, {:duration => 0} )
             p.visual_effect( :switch_on,  hide_id, {:duration => 0} )
             elements.each do |e|
               p.visual_effect( show_effect,  e, effect_opt )
             end
           end
    ret += "</p>"
    ret
  end

end
