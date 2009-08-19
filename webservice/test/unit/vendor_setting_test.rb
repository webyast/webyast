require File.dirname(__FILE__) + '/../test_helper'
require 'vendor_setting'

def test_data(name)
  File.join(File.dirname(__FILE__), "data", name)
end

# example config file
$config_data =<<EOF
bug_url: http://www.bugs.com
packages:
  - mydb-server
  - mydb-console
services:
  - mydb-daemon
  - syslog
eula:
  This is an evil eula that will
  make you think twice before
  clicking it
EOF

class VendorSettingTest < ActiveSupport::TestCase
  
  def setup
    YaST::ConfigFile.stubs(:resolve_file_name).with(:vendor).returns('/foo/vendor.yml')
    YaST::ConfigFile.stubs(:read_file).with('/foo/vendor.yml').returns($config_data)
  end

  def test_config
    settings = VendorSetting.find(:all)
    # look for one setting
    setting = settings.find{ |x| x.name == 'packages'}
    assert_instance_of(Array, setting.value)
    assert_equal("packages", setting.name)
    assert_equal(4, settings.size)
    assert_equal("http://www.bugs.com", VendorSetting.bug_url)
    assert_instance_of(Array, VendorSetting.services)
    assert_equal(2, VendorSetting.services.size)
  end
  
end
