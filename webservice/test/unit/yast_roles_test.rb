require File.dirname(__FILE__) + '/../test_helper'

class CurrentLogin
  attr_reader :login
  
  def initialize login
    @login = login
  end
end

class YastRolesTest < ActiveSupport::TestCase
  include YastRoles
  
  attr_reader :current_account
  
  def setup
    ENV["RAILS_ENV"] = ""
    @current_account = CurrentLogin.new "root" # be brave
  end
    
  def test_permission_check_trivial
    save = ENV["RAILS_ENV"]
    ENV["RAILS_ENV"] = "test"
    assert permission_check(nil)
    ENV["RAILS_ENV"] = save
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

  def test_polkit_override
    def PolKit.polkit_check(action,login) return :yes if action == "test_polkit_override" end
    assert permission_check("test_polkit_override")
  end

  def test_role_ok
    def PolKit.polkit_check(action,login) return :yes if login == "network_admin" end
    assert permission_check("dummy")
  end
  
  def test_role_not_ok
    @current_account = CurrentLogin.new "nobody"
    def PolKit.polkit_check(action,login) return :yes if login == "network_admin" end
    assert !permission_check("dummy")
  end
end
