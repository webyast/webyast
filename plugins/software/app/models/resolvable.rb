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

#
# Model for resolvables available via package kit
#
require "packagekit"

class Resolvable

  attr_accessor   :resolvable_id,
                  :kind,
                  :name,
		  :version,
                  :arch,
                  :repo,
                  :summary

  # default constructor
  def initialize(attributes)
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def id
    @resolvable_id
  end

  def id=(id_val)
    @resolvable_id = id_val
  end

  # get xml representation of instance
  # tag: name of toplevel tag (i.e. :package)
  #
  def to_xml( tag, options = {}, messages=[] )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.tag! tag do
      xml.tag!(:resolvable_id, @resolvable_id, {:type => "integer"} )
      xml.tag!(:kind, @kind )
      xml.tag!(:name, @name )
      xml.tag!(:version, @version )
      xml.tag!(:arch, @arch )
      xml.tag!(:repo, @repo )
      xml.tag!(:summary, @summary )
      unless messages.blank?
        xml.messages(:type => :array) do
          messages.each do |message|
            xml.message do
              xml.tag!(:kind, message[:kind])
              xml.tag!(:details, message[:details])
            end
          end
        end
      end
    end

  end
  
  def to_json( options = {} )
    hash = Hash.from_xml(self.to_xml())
    return hash.to_json
  end

  def self.mtime
    PackageKit.mtime
  end
  
  # installs this
  def install
    PackageKit.install(id)
  end

end
