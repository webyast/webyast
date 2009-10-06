require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require "yast/config_file"

class BasesystemTest < ActiveSupport::TestCase

YAML_CONTENT = <<EOF
steps:
  - controller: systemtimes
  - controller: language
    action: show
EOF

  TEST_STEPS = [{ "controller" => "systemtimes"},{"controller" => "language", "action" => "show"}]
  def setup
    #set const to run test in this directory
    Basesystem.const_set "FINISH_FILE", File.expand_path(File.join(File.dirname(__FILE__),"finish")) 
    YaST::ConfigFile.stubs(:read_file).returns(YAML_CONTENT)
    YaST::ConfigFile.any_instance.stubs(:path).returns(__FILE__)
    @basesystem = Basesystem.find
  end
  
  def teardown
    finish = Basesystem.const_get "FINISH_FILE"
    if File.exist?(finish)
      File.delete(finish)
    end
  end
  
  def test_steps
    assert_equal(TEST_STEPS, @basesystem.steps)
  end  

  def test_finish
    assert !@basesystem.finish
  end

  def test_save
    @basesystem.finish = true
    @basesystem.save
    assert @basesystem.finish
  end  

  def test_to_xml
    assert_not_nil @basesystem.to_xml
  end

  def test_to_json
    assert_not_nil @basesystem.to_json
  end

end
