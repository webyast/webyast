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

require 'yaml'

module YaST
  #
  # Util class to read configuration
  # files no matter what format they
  # are
  #
  # Usage:
  #
  # To parse an arbitrary file:
  # cfg = YaST::ConfigFile.new("/etc/somefile")
  #
  # To parse a file named myconfig.yml
  # from the predefined location YaST::ConfigFile::CONFIG_DEFAULT_LOCATION
  #
  # cfg = YaST::ConfigFile.new(:loc)
  # val = cfg[somekey][someotherkey]
  #
  # The extension will be determined automatically
  #
  # Supported formats are:
  # * yaml
  #
  # If a resource or file is not found ConfigFile::NotFoundError is
  # raised.
  #
  class ConfigFile
    CONFIG_DEFAULT_LOCATION=Paths::CONFIG

    # Error raised when a configuration file
    # or resource is not found
    class NotFoundError < RuntimeError
      attr_accessor :path

      def initialize(path)
        @path = path
      end
    end

    # initializes a config file based on
    # a resource name or a file path
    #
    # if you specfy it using a symbol
    # it will be searched in the default location
    #
    # otherwise the given path is used
    def initialize(name)
      @data = {}
      @file_name = ConfigFile.resolve_file_name(name)
      @loaded = false
    end

    def load_if_needed
      if not @loaded
        load_file(@file_name)
        @loaded = true
      end      
    end
    
    # access a key in the configuration
    def [](key)
      load_if_needed
      @data[key]
    end

    # modifies a key in the configuration
    def []=(key, val)
      load_if_needed
      @data[key] = val
    end

    # iterate over config keys and values
    def each
      load_if_needed
      @data.each do |key, val|
        yield(key, val)
      end
    end

    # true if configuration has a given key
    def has_key?(name)
      load_if_needed
      @data.has_key?(name)
    end

    # the file path where this config is operating on
    # note, this file may not exist at all
    def path
      @file_name
    end

    # returns the xml representation if available
    def to_xml(options = {})
      load_if_needed
      @data.to_xml(options)
    end

    def to_json
      load_if_needed
      @data.to_json
    end
    
    # resolves the file name or nil
    # if it can be resolved
    def self.resolve_file_name(name)
      file_name = name
      if name.is_a?(Symbol)
        file_name = File.join(config_default_location, "#{name}.yml")
      end
      file_name
    end

    # returns the file content
    def self.read_file(file_name)
      raise NotFoundError.new(file_name) if not File.exist?(file_name)
      File.open(file_name, 'r').read
    end
    
    # returns the file content
    def read_file
      ConfigFile.read_file(@file_name)
    end
    
    # loads data from a file and returns
    # the data
    def self.load_file(file_name)
      YAML::load(read_file(file_name))
    end

    # loads data from a file
    def load_file(file_name)
      @data.merge!(ConfigFile.load_file(file_name))
    end
    
    # access the location constant
    def self.config_default_location
      # pattern that rails is following too
      # see
      # http://www.danielcadenas.com/2008/09/stubbingmocking-constants-with-mocha.html
      CONFIG_DEFAULT_LOCATION
    end
    
  end
end
