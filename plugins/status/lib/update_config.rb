#--
# Copyright (c) 2013 Novell, Inc.
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
# This script updates status_configuration.yaml
# Called in RPM %post script
#
# @author Lukas Ocilka <locilka@suse.com>
#


require "yaml"

CONFIGURATION_FILE = "status_configuration.yaml"
PATH = File.join("/var/lib/webyast", "status", CONFIGURATION_FILE)

def update_config()
  if File.exist?(PATH)
    config = YAML.load_file(PATH)
    changed = false

    # bnc#798322 Smaller traffic can produce confusing graphs
    # if Y axis is rounded
    if config['Network'] && config['Network']['y_decimal_places'] == 0
      config['Network']['y_decimal_places'] = 1
      changed = true
    end

    # bnc#798322 Smaller disks (especially in virtual systems) can produce
    # confusing graphs if Y axis is rounded
    if config['Disk'] && config['Disk']['y_decimal_places'] == 0
      config['Disk']['y_decimal_places'] = 1
      changed = true
    end

    save_config(config) if changed
  end
end

def save_config(config)
  File.open(PATH, "w") do |f|
    f.write(config.to_yaml)
  end
end

update_config()
