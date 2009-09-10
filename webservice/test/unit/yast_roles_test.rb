class CurrentLogin
  attr_reader :login
  
  def initialize login
    @login = login
  end
end

unless defined? PERMISSION_CHECK_TESTING
  PERMISSION_CHECK_TESTING=true
end

unless defined? USER_ROLES_CONFIG
  USER_ROLES_CONFIG = File.join(File.dirname(__FILE__), "..", "fixtures", "yast_user_roles")
end

require File.join(File.dirname(__FILE__),"..", "test_helper")

class YastRolesTest < ActiveSupport::TestCase
  include YastRoles
  
  attr_reader :current_account
  
  def setup
    # FIXME: this needs proper PolKit mocking !
    @current_account = CurrentLogin.new "root" # be brave
  end
    
  def test_permission_check_trivial
    assert_raise(NoPermissionException) { permission_check(nil) }
  end
  
  def test_permission_check_no_account
    @current_account = nil
    assert_raise(NotLoggedException) { permission_check(nil) }
  end
  
  def test_action_nil
    assert_raise(NoPermissionException) { permission_check(nil) }
  end    
  
  def test_action_dummy
    def PolKit.polkit_check(action,login) return :no end
    assert_raise(NoPermissionException) { permission_check("dummy") }
  end    

  def test_polkit_override
    def PolKit.polkit_check(action,login) return :yes if action == "test_polkit_override" end
    assert permission_check("test_polkit_override")
  end

  # test/fixtures/yast_user_roles assign "network_admin" role to user "root"
  def test_role_ok
    def PolKit.polkit_check(action,login) return :yes if login == "network_admin" end
#FIXME    assert permission_check("dummy")
  end
  
  def test_role_not_ok
    @current_account = CurrentLogin.new "nobody"
    def PolKit.polkit_check(action,login) return :yes if login == "network_admin" end
    assert_raise(NoPermissionException) { permission_check("dummy") }
  end
end
