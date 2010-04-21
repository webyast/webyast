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

require 'yast/config_file'

module YaST

  # Base class for a model based on a
  # config file with settings
  #
  # child classes need to reimplement
  # config_name to let YaST::ConfigFile
  # find the configuration
  class SettingsModel

    class << self
      attr_accessor :config
    end

    def self.config_name
      config
    end

    def self.config_name=(name)
      self.config = YaST::ConfigFile.new(name)
    end
    
    # initialize a model instance
    def initialize(name)
      @name = name
    end

    def self.path
      self.config.path
    end
    
    # find instances of the model
    def self.find(what)
      ret = nil
      ret = case what
        when :all then find_all
        else find_one(what)
      end
    end

    def self.find_all
      ret = []
      return ret if self.config.nil?
      self.config.each do |key,val|
        ret << self.new(key)
      end
      ret
    end
    
    def self.find_one(id)
      ret = nil
      if self.config.has_key?(id.to_s)
        ret = self.new(id.to_s)
      end
      ret
    end
    
    # setting id, alias for name
    def id
      name.to_s
    end
  
    # setting name
    def name
      @name.to_s
    end

    def value
      self.class.config[name.to_s]
    end

    def self.method_missing(name)
      # look if config has a key
      if self.config.has_key?(name.to_s)
        return self.config[name.to_s]
      end
      raise NoMethodError.new("undefined method `#{name}' for #{self.class.to_s}:Class")
    end

    def self.to_xml
      tag_name = self.to_s.underscore
      self.config.to_xml(:root => tag_name)
    end

    def self.to_json
      self.config.to_json
    end
    
    def to_xml(options = {})
      fixed_value = value
      # quick fix in case the value is an array
      if value.is_a?(Array)
        # convert something like [a,b,c] into [{ :foo => a }, { :foo => b }, ...]
        fixed_value = value.map { |x| { name.singularize => x } }
      end
      { :name => name, :value => fixed_value }.to_xml({:root => self.class.to_s.underscore}.merge(options))
    end

    def to_json
      self.class.config[name].to_json
    end
    
  end
  
end
