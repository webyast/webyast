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

require 'builder'

class InstallInProgressException < BackendException
  def initialize(count)
    @count = count
    super "Cannot obtain available patches, installation is in progress. #{@count} patches remain to install."
  end

  def to_xml(options = { :indent => 2 })
    xml = Builder::XmlMarkup.new(options)
    xml.instruct!

    xml.error do
      xml.type "PACKAGEKIT_INSTALL"
      xml.description message
      xml.count @count, :type => "integer"
      xml.bug false, :type => "boolean"
    end
  end

  def to_json
    { :error => message, :count => @count }.to_json
  end
end
