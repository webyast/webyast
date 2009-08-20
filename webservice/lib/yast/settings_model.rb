
require 'yast/config_file'

module YaST

  # Base class for a model based on a
  # config file with settings
  #
  # child classes need to reimplement
  # config_name to let YaST::ConfigFile
  # find the configuration
  class SettingsModel

    # initialize a model instance
    def initialize(name, value)
      SettingsModel.init
      @name = name
      @value = value
    end

    def self.path
      SettingsModel.init
      @@config.path
    end
    
    # find instances of the model
    def self.find(what)
      SettingsModel.init
      ret = nil
      if what == :all
        ret = []
        @@config.each do |key,val|
          ret << self.new(key, val)
        end  
      end
      ret
    end

    def self.init
      if not defined?(@@config)
        @@config = YaST::ConfigFile.new(@@config_name)
      end
    end

    def self.config_name(name)
      @@config_name = name
    end
    
    # setting id, alias for name
    def id
      name
    end
  
    # setting name
    def name
      @name
    end

    def value
      @value
    end

    def self.method_missing(name)
      SettingsModel.init
      # look if config has a key
      if @@config.has_key?(name.to_s)
        return @@config[name.to_s]
      end
      raise NoMethodError.new("undefined method `#{name}' for #{self.class.to_s}:Class")
    end
  
    def to_xml
      tag_name = self.class.to_s.underscore
      { :name => name, :value => value }.to_xml(:root => tag_name)
    end
  end
  
end
