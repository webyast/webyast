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
    WebyastEngine.find.each do |e|
      Dir["#{e.config.root}/public/restdoc/**/restdoc.html"].each do |restdoc_path|

        if restdoc_path.match /\/public\/restdoc\/(.*)\/restdoc.html$/
          Rails.logger.debug "Found: #{what != :all && what.to_s == $1}"

          if what == :all
            @ret << restdoc_path
          else
            return restdoc_path if what == $1
          end
        end
      end
    end

    return (what == :all) ? @ret : nil
  end
end