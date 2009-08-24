require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require "yast/config_file"

class BasesystemTest < ActiveSupport::TestCase

YAML_CONTENT = <<EOF
steps:
  - systemtime
  - language
EOF

  TEST_STEPS = ["systemtime","language"]
  def setup
    YaST::ConfigFile.stubs(:read_file).returns(YAML_CONTENT)
    @basesystem = Basesystem.find
  end
  
  def teardown
    finish = Basesystem.const_get "FINISH_FILE"
    if File.exist?(finish)
      File.delete(finish)
    end
  end
  
  def test_steps
    @basesystem = Basesystem.find
    assert_equal(TEST_STEPS, @basesystem.steps)
  end  

  def test_finish
    @basesystem = Basesystem.find
    assert !@basesystem.finish
  end

  def test_save
    @basesystem.finish = true
    @basesystem.save
    @basesystem = Basesystem.find
    assert @basesystem.finish
  end  

  def test_to_xml
    assert_not_nil @basesystem.to_xml
  end

  def test_to_json
    assert_not_nil @basesystem.to_json
  end

end
