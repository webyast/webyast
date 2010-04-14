require File.join(File.dirname(__FILE__),"..", "test_helper")

#
# Must be functional test (ActionController::TestCase) since
# AuthenticatedSystem is based on session data
#

class AuthenticatedSystemTest < ActionController::TestCase
  def self.helper_method *args
    # empty ActionView hook
  end
  
  def authenticate_with_http_basic &block
    # empty ActionController hook
  end
    
  include AuthenticatedSystem

  fixtures :accounts
    
  def setup
    @request = ActionController::TestRequest.new
  end
    
  test "login" do
    assert !logged_in?
    assert logged_in? == authorized?
    account = Account.find(:first)
    assert account
    self.current_account = account
    assert logged_in?
    assert logged_in? == authorized?
  end
end
