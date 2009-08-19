
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
    def initialize(name)
      SettingsModel.init
      @name = name
    end

    def self.path
      SettingsModel.init
      @@config.path
    end
    
    # find instances of the model
    def self.find(what)
      SettingsModel.init
      ret = nil
      ret = case what
        when :all then find_all
        else find_one(what)
      end
    end

    def self.find_all
      ret = []
      @@config.each do |key,val|
        ret << self.new(key)
      end
      ret
    end
    
    def self.find_one(id)
      ret = nil
      if @@config.has_key?(id.to_s)
        ret = self.new(id.to_s)
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
      name.to_s
    end
  
    # setting name
    def name
      @name.to_s
    end

    def value
      @@config[name.to_s]
    end

    def self.method_missing(name)
      SettingsModel.init
      # look if config has a key
      if @@config.has_key?(name.to_s)
        return @@config[name.to_s]
      end
      raise NoMethodError.new("undefined method `#{name}' for #{self.class.to_s}:Class")
    end

    def self.to_xml
      tag_name = self.to_s.underscore
      @@config.to_xml(:root => tag_name)
    end

    def self.to_json
      @@config.to_json
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
      @@config[name].to_json
    end
    
  end
  
end
