require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "yast_service"
#require 'mocha'
require 'pp'

class UserTest < Test::Unit::TestCase

  def setup

    #parameters	= { "index" => ["s", "uid"], "user_attributes" => ["as", [ "cn" ]] }
    #YastService.stubs(:Call).with("YaPI::USERS::UsersGet", parameters)

    
  end

  def test_user
    parameters	= { "index" => ["s", "uid"], "user_attributes" => ["as", [ "cn" ]] }
    YastService.stubs(:Call).with("YaPI::USERS::UsersGet", parameters)
    reply = YastService.Call("YaPI::USERS::UsersGet", parameters)
    assert_equal({}, reply)
  end
  
end
