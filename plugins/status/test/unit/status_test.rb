require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'scr'
require 'mocha'
require 'test_helper'

class StatusTest < ActiveSupport::TestCase
#  fixtures :accounts
  def setup
#    @controller = SecuritiesController.new
#    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
  end
=begin
  def test_vailable_metrics
    IO.stubs(:popen).with("ls random_path").returns("cpu memory")
    IO.stubs(:popen).with("ls random_path/cpu").returns("idle")
    IO.stubs(:popen).with("ls random_path/memory").returns("free buffered used")

    status = Status.new
    assert status.available_metrics {"cpu" => {:rrds => "idle"}, "memory" => {:rrds => "free buffered used"}}
  end
=end
end
