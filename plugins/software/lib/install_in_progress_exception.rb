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

class InstallInProgressException < BackendException
	def initialize(count,progress)
		@progress = progress
    @count = count
	end

	def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "PACKAGEKIT_INSTALL"
      xml.description "Cannot obtain patches, installation in progress. Remain #{@count} packages. Status of currently installed package #{@progress.progress}"
			xml.progress @progress
      xml.count @count, :type => "integer"
    end
	end
end
