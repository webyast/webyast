
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'test/unit'
require 'rubygems'
require "yast_service"
require "samba_share"
require 'mocha'
require 'pp'

class SambaShareTest < Test::Unit::TestCase

  def setup
    # stub YaPI calls
    YastService.stubs(:Call).with("YaPI::Samba::GetAllDirectories").returns(["/dr1", "/dir2", "/dir3"])
    
  end

  def test_share
    shares = SambaShare.find_all
    assert_equal(3, shares.size)
  end
  
end
