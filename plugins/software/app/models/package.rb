#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require 'resolvable'

class Package < Resolvable

  def to_xml( options = {} )
    super :package, options
  end

  def self.find(what)
    if what == :installed
      package_list = Array.new
      self.execute("GetPackages", what.to_s, "Package") { |line1,line2,line3| # RORSCAN_ITL
        columns = line2.split ";"
        package = Package.new(:resolvable_id => line2,
                              :name => columns[0],
                              :version => columns[1]
                             )
                            # :arch => columns[2],
                            # :repo => columns[3],
                            # :summary => line3 )
       package_list << package
     }
    package_list
    end
  end
end
