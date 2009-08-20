
require File.dirname(__FILE__) + '/../../test_helper'
require 'yast/settings_model'

def test_data(name)
  File.join(File.dirname(__FILE__), "data", name)
end

# example config file
$config_data =<<EOF
height: 100
width: 300
frequency: 40
mode: vga
outputs:
  - dvi
  - analog
EOF

# example setting model
class MonitorSetting < YaST::SettingsModel
  config_name :monitor  
end

class SettingsModelTest < ActiveSupport::TestCase
  
  def setup
    YaST::ConfigFile.stubs(:resolve_file_name).with(:monitor).returns('/foo/monitor.yml')
    YaST::ConfigFile.stubs(:read_file).with('/foo/monitor.yml').returns($config_data)
  end

  def test_model
    assert_equal('/foo/monitor.yml', MonitorSetting.path)
    settings = MonitorSetting.find(:all)
    assert_equal(5, settings.size)

    # try normal access
    assert_equal(300, MonitorSetting.width)
    assert_instance_of(Array, MonitorSetting.outputs)

    setting = settings.find{ |x| x.name == "height" }

    xml = <<DONE
<?xml version="1.0" encoding="UTF-8"?>
<monitor-setting>
  <value type="integer">100</value>
  <name>height</name>
</monitor-setting>
DONE
    assert_equal(xml, setting.to_xml)
    
  end
  
end
