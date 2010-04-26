#--
# Webyast Webservice framework
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


#
# Resource class
#

class Resource
  require 'resource_registration'
  attr_accessor :implementations, :interface, :controller

  def initialize (interface, impl_hash)
    @interface = interface
    @policy    = impl_hash[:policy]
    @singular  = impl_hash[:singular]
    @controller= impl_hash[:controller]
  end

  def link_to
    "/#{@controller}"
    #               url_for :only_path => :true,
    #                       :controller => @controller,
    #                       :action => (@singular ? :show : :index)
  end

  def action
    @singular ? :show : :index
  end

  def self.all
    resources = []
    ResourceRegistration.resources.sort.each do |interface,implementations|
      implementations.each do |impl|
        resources << new(interface,impl)
      end
    end
    return resources
  end

  def self.find(interface)
    implementations = ResourceRegistration.resources[interface]
    return nil unless implementations
    new(interface, implementations.first)
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.resource do
      xml.interface(@interface)
      xml.policy(@policy)
      xml.singular(@singular, :type => :boolean)
      xml.href(link_to)
    end
  end

  def to_json( options = {} )
    Hash.from_xml(to_xml).to_json
  end
end
