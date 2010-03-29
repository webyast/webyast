#
# This class handles the logfiles
# The yaml file is located in config/logs.yaml
#

require 'yast/config_file'
require 'yast_service'

class Log
  attr_reader :id
  attr_reader :path
  attr_reader :description
  attr_reader :data

  CONFIGURATION_FILE = "logs.yml"
  VENDOR_DIR = "vendor"
  DEFAULT_LINES = 50

  public

  #
  # reading configuration file
  #
  def self.parse_config(path = nil)
    path = File.join(Paths::CONFIG,VENDOR_DIR,CONFIGURATION_FILE) if path == nil

    #reading configuration file
    return YaST::ConfigFile.new(path) if File.exists?(path)
    return nil
  end

  # initialize on element
  def initialize(key, val)
    @id = key
    @path = val["path"]
    @description = val["description"]
    @data = {}
  end

  #
  # find 
  # LOG.find(:all)
  # LOG.find(id) 
  # "id" could be the log group (system,...)
  #
  def self.find(what)
    config = parse_config
    ret = []
    return ret if config==nil

    config.each {|key,value|
      ret << Log.new(key,value) if key==what || what==:all
    }

    if what == :all || ret.blank?
      return ret    
    else
      raise "#{what} not found in configuration file" if ret.blank?
      Rails.logger.error "There are more results for #{what} -> #{ret.inspect} Taking the first one..." if ret.size > 1
      return ret.first
    end
  end

  #
  # evaluate log lines
  # 
  def evaluate_content(pos_begin = 0, lines = DEFAULT_LINES)
    pos_begin = 1 if pos_begin.to_i<0 #just to be sure to be in the valid frame
    @data = YastService.Call("LogFile::Read", ["s",id], ["s",pos_begin.to_s], ["s",lines.to_s])
    if @data["`value"]=="___WEBYAST___INVALID"
      Rails.logger.error "invalid id #{id} with path #{path}"
      raise "Cannot Read logfiles of #{path}"
    end
    Rails.logger.info @data.inspect
    @data
  end

  # converts the log to xml
  def to_xml(opts={})
    xml = opts[:builder] ||= Builder::XmlMarkup.new(opts)
    xml.instruct! unless opts[:skip_instruct]
    xml.log do
      xml.id id
      xml.path path
      xml.description description
      xml.content do
        xml.value data["`value"]
        xml.position data["`position"]
      end unless data.blank?
    end
  end

end
