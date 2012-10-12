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
# This class handles the status of WebYaST plugins
# Each plugin will be checked if it has an REST interface
# "status". This status will be evaluated.
#

require 'yast_service'
require 'builder'

class Plugin
  attr_reader :level
  attr_reader :message_id
  attr_reader :short_description
  attr_reader :long_description
  attr_reader :details
  attr_reader :confirmation_link
  attr_reader :confirmation_label
  attr_reader :confirmation_kind

  public

  # initialize on element
  def initialize(level = "", 
                 message_id = "", 
                 short_description = "", 
                 long_description = "", 
                 details = "", 
                 confirmation_link = "", 
                 confirmation_label = "",
                 confirmation_kind = "")
    @level = level
    @message_id = message_id
    @short_description = short_description
    @long_description = long_description
    @details = details
    @confirmation_link = confirmation_link
    @confirmation_label = confirmation_label
    @confirmation_kind = confirmation_kind
  end

  #
  # find 
  # Plugin.find(:all)
  # Plugin.find(id) 
  # "id" is the plugin name
  #
  def self.find(what)
    models = []
    ret = []
    resources = Resource.find :all
    resources.each {|resource|
      name = resource.href.split("/").last
      models << (name+"_state").classify if name==what || what==:all
    }

    models.each {|model|
      status = Object.const_get(model) rescue $!
      if status.class != NameError && status.respond_to?(:read)
        stat = status.read
        ret << Plugin.new(stat[:level], stat[:message_id], 
                          stat[:short_description], stat[:long_description], 
                          stat[:details], stat[:confirmation_link], 
                          stat[:confirmation_label], stat[:confirmation_kind] ) unless stat.blank?
      end
    }
    ret
  end

  # converts the status to xml
  def to_xml(opts={})
    xml = opts[:builder] ||= Builder::XmlMarkup.new(opts)
    xml.instruct! unless opts[:skip_instruct]
    xml.plugin do
      xml.level level
      xml.message_id message_id
      xml.short_description short_description
      xml.long_description long_description
      xml.details details
      xml.confirmation_link confirmation_link
      xml.confirmation_label confirmation_label
      xml.confirmation_kind confirmation_kind
    end
  end

end
