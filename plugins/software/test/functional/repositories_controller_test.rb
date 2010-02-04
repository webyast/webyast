require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'mocha'


class RepositoriesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = RepositoriesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    @r1 = Repository.new("factory-oss", "FACTORY-OSS", true)
    @r2 = Repository.new("factory-non-oss", "FACTORY-NON-OSS", false)

    Repository.stubs(:find).with(:all).returns([@r1, @r2])
    Repository.stubs(:find).with('factory-oss').returns([@r1])
    Repository.stubs(:find).with('none').returns([])
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
    get :show, :id =>"factory-oss"
    assert_response :success
  end

  test "access show xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :format => :xml, :id =>"factory-oss"
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access show json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :format => :json, :id =>"factory-oss"
    assert_equal mime.to_s, @response.content_type
  end

  test "access repo with wrong id" do
    get :show, :id =>"none"
    assert_response 404
  end

end
