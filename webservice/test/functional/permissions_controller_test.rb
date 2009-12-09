#
# Testing PermissionsController
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'mocha'


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

  def setup
    @request.session[:account_id] = 1 #fixtures
    Permission.any_instance.stubs(:all_actions).returns(TEST_DATA_ACTIONS)
    PolKit.stubs(:polkit_check).returns(:yes)
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
