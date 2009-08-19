
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
    CONFIG_DEFAULT_LOCATION="/etc/YaST2"

    # Error raised when a configuration file
    # or resource is not found
    class NotFoundError < RuntimeError
    end

    # initializes a config file based on
    # a resource name or a file path
    #
    # if you specfy it using a symbol
    # it will be searched in the default location
    #
    # otherwise the given path is used
    def initialize(name)
      @file_name = ConfigFile.resolve_file_name(name)
      load_file(@file_name)
    end

    # access a key in the configuration
    def [](key)
      @data[key]
    end

    # modifies a key in the configuration
    def []=(key, val)
      @data[key] = val
    end

    # iterate over config keys and values
    def each
      @data.each do |key, val|
        yield(key, val)
      end
    end

    # true if configuration has a given key
    def has_key?(name)
      @data.has_key?(name)
    end

    # the file path where this config is operating on
    def path
      @file_name
    end

    # returns the xml representation if available
    def to_xml(options = {})
      @data.to_xml(options)
    end

    def to_json
      @data.to_json
    end
    
    # resolves the file name
    # and throws NotFoundError if
    # it can't be resolved
    def self.resolve_file_name(name)
      file_name = name
      if name.is_a?(Symbol)
        file_name = File.join(config_default_location, "#{name}.yml")
      end
      # simple case first
      raise NotFoundError if not File.exist?(file_name)
      file_name
    end

    # returns the file content
    def self.read_file(file_name)
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
      @data = ConfigFile.load_file(file_name)
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
