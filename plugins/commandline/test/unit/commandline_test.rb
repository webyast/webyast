require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class CommandlineTest < ActiveSupport::TestCase
  require "commandline"
  
  test "commandline each" do
    Commandline.each do |foo|
      assert foo
    end
  end
end