# = Base system model
# Provides access to basic system settings module queue. Provides and updates
# if base system settings is already done.
require "yast/config_file"
require "exceptions"
class Basesystem

  # steps needed by base system
  attr_accessor   :steps
  # Flag if base system configuration is  finished
  attr_accessor   :finish

  # path to file which defines module queue
  BASESYSTEM_CONF = :basesystem
  # path to file which store module then is next in queue or END_STRING if all steps is done
  FINISH_FILE = File.join(Paths::VAR,"basesystem","finish")


  #Gets instance of Basesystem with initialized steps queue.
  def initialize
    @steps = []
    @finish = false
  end

  #Gets instance of Basesystem with initialized steps queue and if basic settings is done
  def Basesystem.find
    base = Basesystem.new
    base.finish = File.exist?(FINISH_FILE)
    config = YaST::ConfigFile.new(BASESYSTEM_CONF)
    if File.exist?(config.path)
      begin
	base.steps = config["steps"] || []
      rescue Exception => e
	raise CorruptedFileException.new(config.path)
      end
    else
      base.steps = []
    end
    return base
  end

  #stores to system Basesystem settings
  def save
    if @finish
      FileUtils.touch FINISH_FILE unless File.exist?(FINISH_FILE)
    end
  end

  #serialize part of Basesystem to xml
  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.basesystem do
      xml.finish(@finish,{:type => "boolean"})
      xml.steps({:type => "array"}) do
        @steps.each do
          |step|
          xml.step do
            xml.controller step["controller"]
            xml.action step["action"]
          end
        end
      end
    end
  end

  #serialize part of Basesystem to json
  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end
end

