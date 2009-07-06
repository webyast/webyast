require File.dirname(__FILE__) + '/../test_helper'

class CurrentLogin
  attr_reader :login
  
  def initialize login
    @login = login
  end
end

class YastRolesTest < ActiveSupport::TestCase
  include YastRoles
  
  session = Hash.new

  attr_reader :current_account
  
  def setup
    ENV["RAILS_ENV"] = ""
    @current_account = CurrentLogin.new "test"
  end
    
  def test_permission_check_trivial
    ENV["RAILS_ENV"] = "test"
    assert permission_check(nil)
  end
  
  def test_permission_check_no_account
    @current_account = nil
    assert !permission_check(nil)
  end
  
  def test_action_nil
    assert !permission_check(nil)
  end    
  
  def test_action_dummy
    assert !permission_check("dummy")
  end    
end
