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

#Haml gettext module providing gettext translation for all Haml plain text calls
#
# http://pastie.org/445295
#

class Haml::Engine
  # Inject _ gettext into plain text and tag plain text calls
  def push_plain(text)
    super(_(text))
  end

  def parse_tag(line)
    tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
      nuke_inner_whitespace, action, value = super(line)
    value = _(value) unless action || value.empty?
      [tag_name, attributes, attributes_hash, object_ref, nuke_outer_whitespace,
        nuke_inner_whitespace, action, value]
   end
end
