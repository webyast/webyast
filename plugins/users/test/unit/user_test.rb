require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "yast_service"
require 'mocha'
require 'pp'

class UserTest < Test::Unit::TestCase

  def setup

    parameters	= { "index" => ["s", "uid"], "user_attributes" => ["as", [ "cn" ]] }
    YastService.stubs(:Call).with("YaPI::USERS::UsersGet", parameters).returns({"testuser1"=>{"cn"=>"testuser1"}, "testuser2"=>{"cn"=>"testuser2"}})    
  end

  def test_user
    users = User.find_all
    assert_equal(2, users.size)
  end
  
end
