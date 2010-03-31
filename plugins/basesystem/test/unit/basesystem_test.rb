require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require "yast/config_file"

class BasesystemTest < ActiveSupport::TestCase

YAML_CONTENT = <<EOF
steps:
  - controller: time
  - controller: language
    action: show
EOF

  TEST_STEPS = [{ "controller" => "time"},{"controller" => "language", "action" => "show"}]
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
    nbase = Basesystem.find
    assert nbase.finish
  end  

  def test_save_step
    @basesystem.done = "time"
    @basesystem.save
    nbase = Basesystem.find
    assert !nbase.finish
    assert_equal "time", nbase.done
  end

  def test_to_xml
    assert_not_nil @basesystem.to_xml
  end

  def test_to_json
    assert_not_nil @basesystem.to_json
  end

  # Test what happens if the config file is not found
  # bnc#592584
  def test_broken_config
    YaST::ConfigFile.any_instance.stubs(:path).returns("")
    assert_nothing_raised do Basesystem.find end
  end
end
