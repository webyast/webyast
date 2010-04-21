#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

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
    yield "test_user", "password"
  end
    
  include AuthenticatedSystem

  fixtures :accounts
    
  def setup
    @request = ActionController::TestRequest.new
    # put username and password into request
    # -> flip.netzbeben.de/2008/06/functional-test-for-http-authentication-in-rails-2/
 #   @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("test_user:password")
  end
    
  test "login by session" do
    assert !logged_in?
    assert logged_in? == authorized?
    account = Account.find(:first)
    assert account
    self.current_account = account
    assert logged_in?
    assert logged_in? == authorized?
  end

#  test "login by basic auth" do
#    self.current_account = nil
#    assert logged_in?
#    assert logged_in? == authorized?
#  end
end
