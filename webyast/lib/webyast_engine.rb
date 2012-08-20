#--
# Webyast framework
#
# Copyright (C) 2012 Novell, Inc.
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


# Funtionality related to WebYaST engines (plugins)
class WebyastEngine

  # find all or specified WebYaST engines
  # can be used to detect which WebYaST modules are installed
  def self.find what = :all
    regexp = (what == :all) ? /^WebYaST::\S*Engine$/ : "^WebYaST::#{Regexp.escape(what.to_s)}Engine$"

    Rails::Engine::Railties.engines.find_all do |e|
      e.class.to_s.match regexp
    end
  end

end
