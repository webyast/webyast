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
# This "GET show" request will be called for each plugin.
# The loop over all available plugins is defined in checks.rake
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class PluginShowTest < ActionController::TestCase
  fixtures :accounts
  def setup
    puts "Checking #{$pluginname}"
    @controller = Module.recursive_const_get( $pluginname ).new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
  test "access show" do
    get :show
    assert_response :success
  end

end
