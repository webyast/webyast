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


require 'yast/settings_model'

# model representing the settings
# in the vendor configuration file
#
# it can be used in two ways:
#
# settings = VendorSetting.find(:all)
# settings.each do |setting|
#   setting.name 
#   setting.value
# end
#
# or accessing the setting directly:
# VendorSetting.eula
# => text
#
class VendorSetting < YaST::SettingsModel
  self.config_name = :vendor
end
