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


class Restdoc

  def self.find(what)
    @ret = []

    # iterate over all webyast engines
    Rails::Engine::Railties.engines.each do |e|
      if e.class.to_s.match /^WebYaST::\S*Engine$/
        Dir["#{e.config.root}/public/**/restdoc/index.html"].each do |restdoc_path|

          restdoc_path.match /\/public\/((.*)\/restdoc\/index.html)/
          @ret << $1 if $1 && (what == :all || what.to_s == $2)
        end
      end
    end

    return @ret
  end
end