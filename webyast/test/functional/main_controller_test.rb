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

#
# main_controller_test.rb
#
require File.dirname(__FILE__) + '/../test_helper'

class MainControllerTest < ActionController::TestCase
  fixtures :accounts

  test "main index no session" do
    @request.session[:account_id] = nil
    get :index
    assert_redirected_to :controller => "session", :action => "new"
  end
  
  test "main index with session" do
    # Fake an active session
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = Account.find(:first).id
    get :index
    assert_redirected_to :controller => "controlpanel", :action => "index"	
  end
end
