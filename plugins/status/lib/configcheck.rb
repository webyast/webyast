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
# Model over collectd data
#
# @author Bjoern Geuken <bgeuken@suse.de>
# @author Duncan Mac-Vicar P. <dmacvicar@suse.de>
# @author Stefan Schubert <schubi@suse.de>
#


require "yaml"
require 'yast/paths'

CONFIGURATION_FILE = "status_configuration.yaml"
KNOWN_KEYS = ['Network', 'CPU', 'Memory', 'Disk']
PATH = File.join(YaST::Paths::VAR, "status", CONFIGURATION_FILE)
    
def check_config()
  if File.exist?(PATH)
    hash = Hash.new
    hash = YAML.load(File.open(PATH))

    if node_exist?(hash)
      #find headlines
      unless subnode_exist?(hash, "headline")
	add_headline(hash)

	#check label translation
	unless !subnode_exist?(hash, "y_label")
	  check_label_translation(hash)
	end 
      end
    end
    #save changes
    save_config(hash)
  end
end

def node_exist?(hash)
    KNOWN_KEYS.any? { |e| hash.has_key?(e) }
end 

def subnode_exist?(hash, string)
  hash.any? { |key,subhash| subhash.has_key?(string) }
end

def add_headline(hash)
  hash.each do |key, subhash|
    subhash['headline'] = '_("' + key + '")' if KNOWN_KEYS.include?(key)
  end
end

def check_label_translation(hash)
  hash.each do |key, subhash|
    subhash['y_label'] = '_("' + subhash["y_label"] + '")' unless subhash['y_label'] =~ /^_\(\"/ &&  subhash["y_label"] =~ /\"\)$/
  end
end

def save_config(hash)
  file_name = File.join(PATH)
  File.open(file_name, "w") do |f|
    f.write(hash.to_yaml)
  end
end

#run config check
check_config()

