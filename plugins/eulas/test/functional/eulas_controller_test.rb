require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'license'
require 'rubygems'
require 'mocha'

class EulasControllerTest < ActionController::TestCase
  YAML_CONTENT = <<EOF
licenses:
  - openSUSE-11.1
  - SLED-10-SP3
EOF

  UPDATE_DATA = {"id"=>"1", 
                 "format"=>"xml",
                 "eulas"=>{"name"    =>"openSUSE-11.1", 
                           "id"      =>"1", 
                           "accepted"=>"true"
                          }
                }

  def setup
    License.const_set 'RESOURCES_DIR', File.join(File.dirname(__FILE__),"..","..","test","share")
    License.const_set 'VAR_DIR'      , File.join(File.dirname(__FILE__),"..","..","test","var")
    YaST::ConfigFile.stubs(:read_file).returns(YAML_CONTENT)
    YaST::ConfigFile.any_instance.stubs(:path).returns(__FILE__)
    License.any_instance.stubs(:save).returns(nil)

    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    # @test_license = License.new "openSUSE-11.1"
  end

  def test_index
    ["xml", "json"].each do |format|
      get :index, {:format => format}
      assert_response :success
    end
  end

  def test_show
    ["xml", "json"].each do |format|
      get :show, {:format => format, :id => "1"}
      assert_response :success
    end
  end

  def test_update
    License.any_instance.expects(:save).returns(nil)
    get :update, UPDATE_DATA
    assert_response :success
  end

end
