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
logs:
  - /var/log/messages
  - /var/log/apache2/access_log
EOF

    YaST::ConfigFile.stubs(:read_file).with('/etc/webyast/vendor.yml').returns(@config_data)
  end

  def teardown
  end
  
  def test_config
    settings = VendorSetting.find(:all)

    assert_equal(5, settings.size)

    assert_equal("http://www.bugs.com", VendorSetting.bug_url)
    assert_instance_of(Array, VendorSetting.services)
    assert_equal(2, VendorSetting.services.size)
    
    # look for one setting
    setting = VendorSetting.find('packages')
    assert_instance_of(Array, setting.value)
    assert_equal("packages", setting.name)    
  end
  
end
