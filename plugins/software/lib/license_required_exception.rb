#--
# Copyright (c) 2009-2011 Novell, Inc.
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

class LicenseRequiredException < BackendException
	def initialize
    super "License confirm required to continue with installation. Please go to patch module, where you can decide about license confirmation."
	end

	def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "PACKAGEKIT_LICENSE"
      xml.description message
      xml.bug false, :type => "boolean"
    end
	end
end
