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
  BASESYSTEM_CONF_VENDOR	= File.join(Paths::CONFIG,"vendor","basesystem.yml")
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
    basesystem_conf	= BASESYSTEM_CONF
    basesystem_conf	= BASESYSTEM_CONF_VENDOR if File.exists? BASESYSTEM_CONF_VENDOR
    config = YaST::ConfigFile.new(basesystem_conf)
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
        if base.steps.empty? #empty step definition
          base.finish = true
        else
        	base.done = base.steps.first["controller"]
        end
      end
    else
      base.steps = []
      base.finish = true
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

