
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
