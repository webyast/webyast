require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require "yast_service"
require 'mocha'
require 'pp'

class UserTest < Test::Unit::TestCase

  def setup

    parameters	= { "index" => ["s", "uid"], "user_attributes" =>  
        [ "as", [ "cn", "uidNumber", "homeDirectory",
                  "grouplist", "uid", "loginShell", "groupname" ] ]
    }
    YastService.stubs(:Call).with("YaPI::USERS::UsersGet", parameters).returns({"testuser1"=>{"cn"=>"testuser1", "groupname"=>"users", "uidNumber"=>1000, "homeDirectory"=>"/home/testuser1"},
										"testuser2"=>{"cn"=>"testuser2", "groupname"=>"users", "uidNumber"=>1010, "homeDirectory"=>"/home/testuser1"}})    
  end

  def test_user
    users = User.find_all
    assert_equal(2, users.size)
  end
  
end
