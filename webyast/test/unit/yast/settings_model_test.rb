#--
# Webyast Webservice framework
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

require File.dirname(__FILE__) + '/../../test_helper'
require 'yast/settings_model'

def test_data(name)
  File.join(File.dirname(__FILE__), "data", name)
end

# example setting model
class MonitorSetting < YaST::SettingsModel
  self.config_name = :monitor  
end

class SettingsModelTest < ActiveSupport::TestCase
  
  def setup
    # example config file
    @config_data =<<EOF
height: 100
width: 300
frequency: 40
mode: vga
outputs:
  - dvi
  - analog
EOF

    YaST::ConfigFile.stubs(:read_file).with('/etc/webyast/monitor.yml').returns(@config_data)
  end

  def teardown
  end
  
  def test_model
    assert_equal('/etc/webyast/monitor.yml', MonitorSetting.path)
    settings = MonitorSetting.find(:all)
    assert_equal(5, settings.size)

    # try normal access
    assert_equal(300, MonitorSetting.width)
    assert_instance_of(Array, MonitorSetting.outputs)

    setting = MonitorSetting.find(:height)
    assert_equal(100, setting.value)

    xml = <<DONE
<?xml version="1.0" encoding="UTF-8"?>
<monitor-setting>
  <value type="integer">100</value>
  <name>height</name>
</monitor-setting>
DONE
    assert_equal(xml, setting.to_xml)

    assert_equal("100", setting.to_json)

xml = <<END
<?xml version="1.0" encoding="UTF-8"?>
<monitor-settings type="array">
  <monitor-setting>
    <value>vga</value>
    <name>mode</name>
  </monitor-setting>
  <monitor-setting>
    <value type="integer">100</value>
    <name>height</name>
  </monitor-setting>
  <monitor-setting>
    <value type="integer">40</value>
    <name>frequency</name>
  </monitor-setting>
  <monitor-setting>
    <value type="array">
      <value>
        <output>dvi</output>
      </value>
      <value>
        <output>analog</output>
      </value>
    </value>
    <name>outputs</name>
  </monitor-setting>
  <monitor-setting>
    <value type="integer">300</value>
    <name>width</name>
  </monitor-setting>
</monitor-settings>
END
    
    assert_equal(xml, settings.to_xml)

    #assert_equal("d", settings.to_json)
    
  end
  
end
