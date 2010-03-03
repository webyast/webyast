require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'mocha'

class RolesControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    #set fixtures
    Role.const_set(:ROLES_DEF_PATH, File.join( File.dirname(__FILE__), "..","fixtures","roles.yml"))
    Role.const_set(:ROLES_ASSIGN_PATH, File.join( File.dirname(__FILE__), "..","fixtures","roles_assign.yml"))
    @model_class = Role
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  def test_index
    get :index
    assert_response :success
    h=Hash.from_xml @response.body
    assert_equal 3, h['roles'].size
  end

  def test_show
    get :show, :format => 'xml', :id => "test"
    assert_response :success
    h=Hash.from_xml @response.body
    assert_equal 3,h['role']['users'].size
  end
end
