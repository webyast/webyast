require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class PatchesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = PatchesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    PatchesController.any_instance.stubs(:get_updateList).with().returns([Patch.new("462","important","softwaremgmt","noarch","openSUSE-11.0-Updates","Various fixes for the software management stack")])
  end
  
  test "access index" do
    get :index
    assert_response :success
  end

  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :format => :xml
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index, :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  test "access show" do
    get :show, :id =>"462"
    assert_response :success
  end

  test "access show xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :format => :xml, :id =>"462"
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access show json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :format => :json, :id =>"462"
    assert_equal mime.to_s, @response.content_type
  end

  test "access show with wrong id" do
    get :show, :id =>"not_found"
    assert_response 404
  end

  test "installing a patch" do
    PatchesController.any_instance.stubs(:install_update).with("462").returns(true)
    put :update, :id =>"462"
    assert_response :success
  end

  test "installing a patch with wrong ID" do
    PatchesController.any_instance.stubs(:install_update).with("462").returns(true)
    put :update, :id =>"wrong_id"
    assert_response 404
  end


end
