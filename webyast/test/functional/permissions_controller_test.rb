#--
# Webyast framework
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
# Testing PermissionsController
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'mocha'
require 'polkit'

class PermissionsControllerTest < ActionController::TestCase
  fixtures :accounts

TEST_DATA_ACTIONS = <<EOF
org.opensuse.yast.modules.ysr.statelessregister
org.opensuse.yast.modules.ysr.getregistrationconfig
org.opensuse.yast.modules.ysr.setregistrationconfig
org.freedesktop.network-manager-settings.system.modify
org.opensuse.yast.module-manager.import
org.opensuse.yast.module-manager.lock
org.opensuse.yast.modules.yapi.users.usersget
org.opensuse.yast.modules.yapi.users.userget
org.opensuse.yast.modules.yapi.users.usermodify
org.opensuse.yast.modules.yapi.users.useradd
org.opensuse.yast.modules.yapi.users.userdelete
org.opensuse.yast.permissions.read
org.opensuse.yast.permissions.write
EOF

TEST_DATA_GRANT = [
"org.opensuse.yast.modules.ysr.statelessregister",
"org.opensuse.yast.modules.ysr.getregistrationconfig",
"org.freedesktop.network-manager-settings.system.modify",
"org.opensuse.yast.module-manager.import"]

  def setup
    @request.session[:account_id] = 1 #fixtures
    Permission.any_instance.stubs(:all_actions).returns(TEST_DATA_ACTIONS)
    PolKit.stubs(:polkit_check).with(){ |p,u| TEST_DATA_GRANT.include? p.to_s}.returns(:yes)
    PolKit.stubs(:polkit_check).with(){ |p,u| !TEST_DATA_GRANT.include?(p.to_s)}.returns(:no)
  end
  
#TODO more tests (not enough permissions etc.)

  test "permissions access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :user_id => "test_user", :format => 'xml'
    assert_response :success
    assert_equal mime.to_s, @response.content_type
  end

  test "permissions access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :user_id => "test_user", :format => 'json'
    assert_response :success
    assert_equal mime.to_s, @response.content_type
  end

end
