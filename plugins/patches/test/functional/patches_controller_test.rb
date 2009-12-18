require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'mocha'


class PatchesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = PatchesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    # we make them member variables so we can use
    # in other assertions
    @p1 = Patch.new(
            :resolvable_id => "462",
            :name => "softwaremgmt",
            :kind => "important",
            :summary => "Various fixes for the software management stack",
            :arch => "noarch",
            :repo => "openSUSE-11.1-Updates")

    @p2 = Patch.new(
            :resolvable_id => "463",
            :name => "yast",
            :kind => "security",
            :summary => "Various fixes",
            :arch => "noarch",
            :repo => "openSUSE-11.1-Updates")

    Patch.stubs(:mtime).returns(Time.now)
    Patch.stubs(:find).with(:available, {:background => nil}).returns([@p1, @p2])
    Patch.stubs(:find).with('462').returns(@p1)
    Patch.stubs(:find).with('wrong_id').returns(nil)
    Patch.stubs(:find).with('not_found').returns(nil)

    @p1.stubs(:install).returns(true)
  end
  
  test "access index" do
    get :index
    assert_response :success
  end

  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index
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
    put :update, :id =>"462"
    assert_response :success
  end

  test "installing a patch with wrong ID" do
    put :update, :id =>"wrong_id"
    assert_response 404
  end


end
