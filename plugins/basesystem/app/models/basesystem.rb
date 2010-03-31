# = Base system model
# Provides access to basic system settings module queue. Provides and updates
# if base system settings is already done.
require "yast/config_file"
require "exceptions"
class Basesystem < BaseModel::Base

  # steps needed by base system
  attr_accessor   :steps
  # Flag if base system configuration is  finished
  attr_accessor   :finish
  attr_accessor   :done

  # path to file which defines module queue
  BASESYSTEM_CONF = :basesystem
  # path to file which store module then is next in queue or END_STRING if all steps is done
  FINISH_FILE = File.join(Paths::VAR,"basesystem","finish")
  FINISH_STR = "FINISH"

  def initialize(options={})
   @finish = false
   super options
  end

  #Gets instance of Basesystem with initialized steps queue and if basic settings is done
  def Basesystem.find
    base = Basesystem.new
    config = YaST::ConfigFile.new(BASESYSTEM_CONF)
    if File.exist?(config.path)
      begin
      	base.steps = config["steps"] || []
      rescue Exception => e
      	raise CorruptedFileException.new(config.path)
      end
      if File.exist?(FINISH_FILE)
	begin
	  base.done = IO.read(FINISH_FILE)
	rescue Exception => e
	  raise CorruptedFileException.new(FINISH_FILE)
	end
	base.done = FINISH_STR if base.done.blank? #backward compatibility, when touch indicate finished bs
	if base.done == FINISH_STR
	  base.finish = true
	end
      else
	base.done = base.steps.first["controller"]
      end
    else
      base.steps = []
      base.done = true
    end
    return base
  end

  #stores to system Basesystem settings
  def save
    str = @finish ? FINISH_STR : done
    File.open(FINISH_FILE,"w") do |io|
      io.write str
    end
  end
end

