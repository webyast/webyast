require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class GroupsControllerTest < ActionController::TestCase
  fixtures :accounts

  GROUP_READ_DATA = { 'more_users' => { 'games' => 1,
                                        'tux' => 1
                                      },
                      'userlist' => {},
                      'gidNumber' => 100,
                      'cn' => 'users',
                      'userPassword' => 'x',
                      'type' => 'local'
                    }

  GROUP_LOCAL_CONFIG = { "type" => ["s","local"], "gidNumber" => ["i",100] }
``
  GROUP_SYSTEM_CONFIG = { "type" => ["s","system"], "gidNumber" => ["i",100] }

  GROUP_PARAM_DATA = { "old_gid" => 100,
                       "gid" => 101,
                       "members" => ["games","tux"],
                       "cn" => "users"
                     }

  CREATE_DATA = { "group" => GROUP_PARAM_DATA }

  UPDATE_DATA = { "id" => "100", "group" => GROUP_PARAM_DATA }

  GROUP_WRITE_DATA= { 'userlist' => ["as", [] ],
                      'gidNumber' => ["i", 101],
                      'cn' => ["s",'users']
                    }

  OK_RESULT = ""

  def setup
    @model_class = Group
    group_mock = Group.new(GROUP_READ_DATA)
    Group.stubs(:find).returns(group_mock)

    @controller = GroupsController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = UPDATE_DATA
  end

  include PluginBasicTests

  def test_update
    mock_save
    put :update, UPDATE_DATA
    assert_response :success
  end

  def test_create
    mock_save
    put :create, CREATE_DATA
    assert_response :success
  end

  def mock_save
    YastService.stubs(:Call).with( "YaPI::USERS::GroupsModify", GROUP_LOCAL_CONFIG, GROUP_WRITE_DATA).once.returns(OK_RESULT)
    Group.stubs(:permission_check)
  end
end

