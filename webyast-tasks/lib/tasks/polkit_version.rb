#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

# Prepare to handle a package with 'osc'"

#
# obs_project, package_name = osc_prepare
#

require 'yaml'

WEBYAST_CONFIG_FILE = "/etc/webyast/config.yml"
def polkit1
  #checking which policykit is used
  polkit1_enabled = true
  if File.exist?(WEBYAST_CONFIG_FILE)
    values = YAML::load(File.open(WEBYAST_CONFIG_FILE, 'r').read)
    polkit1_enabled = false if values["polkit1"] == false
  end
  polkit1_enabled
end
