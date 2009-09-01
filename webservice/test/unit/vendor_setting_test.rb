require File.dirname(__FILE__) + '/../test_helper'
require 'vendor_setting'
require 'pp'

def test_data(name)
  File.join(File.dirname(__FILE__), 'yast', 'data', name)
end

class VendorSettingTest < ActiveSupport::TestCase
  
  def setup
    # example config file
    @config_data =<<EOF
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

    YaST::ConfigFile.stubs(:read_file).with('/etc/YaST2/vendor.yml').returns(@config_data)
  end

  def teardown
  end
  
  def test_config
    settings = VendorSetting.find(:all)

    assert_equal(4, settings.size)

    assert_equal("http://www.bugs.com", VendorSetting.bug_url)
    assert_instance_of(Array, VendorSetting.services)
    assert_equal(2, VendorSetting.services.size)
    
    # look for one setting
    setting = VendorSetting.find('packages')
    assert_instance_of(Array, setting.value)
    assert_equal("packages", setting.name)    
  end
  
end
