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

#
# This class handles the logfiles
# The yaml file is located in config/logs.yaml
#

require 'yast/config_file'

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
    path = File.join(Paths::CONFIG,CONFIGURATION_FILE) unless File.exists?(path)

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
    YastCache.fetch("log:find:#{what.inspect}") {
      config = parse_config || {}
      ret = []
      config.each {|key,value|
        ret << Log.new(key,value) if key==what || what==:all
      }
      if ret.size > 1
        Rails.logger.error "There are more results for #{what} -> #{ret.inspect} Taking the first one..." 
      end
      ret.first
    }
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
