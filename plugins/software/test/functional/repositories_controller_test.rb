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
    assert_response :missing
  end


  test "index - dbus_exception" do
    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.stubs(:find).raises(DBus::Error, msg_err)

    get :index
    assert_response :missing
  end

  test "show - dbus_exception" do
    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.stubs(:find).raises(DBus::Error, msg_err)

    get :show, :id => "factory-oss"
    assert_response :missing
  end

  test "update" do
    Repository.any_instance.expects(:save).returns(true)

    put :update, :id => "factory-oss", :repositories => {:name => 'New name'}
    assert_response :success
  end

  test "update - save failed" do
    Repository.any_instance.expects(:save).returns(false)

    put :update, :id => "factory-oss", :repositories => {:name => 'New name'}
    assert_response :missing
  end

  test "update empty parameters" do
    Repository.any_instance.expects(:save).never

    put :update, :id => "factory-oss", :repositories => {}
    assert_response :missing
  end

  test "create" do
    Repository.any_instance.expects(:save).returns(true)

    put :create, :id => "factory-oss", :repositories => {:name => 'name'}
    assert_response :success
  end

  test "create empty parameters" do
    Repository.any_instance.expects(:save).never

    put :create, :id => "factory-oss", :repositories => {}
    assert_response :missing
  end

  test "create save failed" do
    Repository.any_instance.expects(:save).returns(false)

    put :create, :id => "factory-oss", :repositories => {:name => 'name'}
    assert_response :missing
  end

  test "destroy" do
    Repository.any_instance.expects(:destroy).returns(true)

    post :destroy, :id => "factory-oss"
    assert_response :success
  end

  test "destroy non-existing repo" do
    Repository.any_instance.expects(:destroy).never

    post :destroy, :id => "none"
    assert_response :missing
  end

  test "destroy failed" do
    Repository.any_instance.expects(:destroy).returns(false)

    post :destroy, :id => "factory-oss"
    assert_response :missing
  end


  # Test Dbus exception handling
  test "update - dbus_exception" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.any_instance.stubs(:save).raises(DBus::Error, msg_err)

    put :update, :id => "factory-oss", :repositories => {:name => 'name'}
    assert_response :missing
  end

  test "create - dbus_exception" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.any_instance.stubs(:save).raises(DBus::Error, msg_err)

    post :create, :id => "factory-oss", :repositories => {:name => 'name'}
    assert_response :missing
  end

  test "destroy - dbus_exception in find" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.stubs(:find).raises(DBus::Error, msg_err)

    post :destroy, :id => "factory-oss"
    assert_response :missing
  end

   test "destroy - dbus_exception in destroy" do

    msg_err = DBus::Message.new(DBus::Message::ERROR)
    msg_err.error_name = 'DBus error'

    Repository.any_instance.stubs(:destroy).raises(DBus::Error, msg_err)

    post :destroy, :id => "factory-oss"
    assert_response :missing
  end

  # Test cache expiration
  test "cache expired" do
    cached = Time.utc(2010,"jan",1,20,0,0)  #=> Fri Jan 01 20:00:00 UTC 2010
    modified = cached + 60                   # modified 1 minute after caching
    current_time = modified + 60             # now it's 1 minute after the modification
    Time.stubs(:now).returns(current_time)

    Rails.cache.expects(:read).with(RepositoriesController::CACHE_ID).returns(cached)
    Repository.expects(:mtime).returns(modified)

    # check that the actions are expired
    @controller.expects(:expire_action).with(:action => :index, :format => nil)
    @controller.expects(:expire_action).with(:action => :show, :format => nil)

    Rails.cache.expects(:write).with(RepositoriesController::CACHE_ID, current_time)

    get :index
  end

  test "cache still valid" do
    cached = Time.utc(2010,"jan",1,20,0,0)  #=> Fri Jan 01 20:00:00 UTC 2010
    modified = cached - 60                   # modified 1 minute before caching
    current_time = cached + 60               # now it's 1 minute after caching the first call
    Time.stubs(:now).returns(current_time)

    Rails.cache.expects(:read).with(RepositoriesController::CACHE_ID).returns(cached)
    Repository.expects(:mtime).returns(modified)

    # check that the actions are not expired
    @controller.expects(:expire_action).never
    # do not update the cache time stamp
    Rails.cache.expects(:write).never

    get :index
  end

  test "not cached yet" do
    cached = nil                               # not cached yet
    modified = Time.utc(2010,"jan",1,20,0,0)  #=> Fri Jan 01 20:00:00 UTC 2010
    current_time = modified + 60               # now it's 1 minute after the modification
    Time.stubs(:now).returns(current_time)

    Rails.cache.expects(:read).with(RepositoriesController::CACHE_ID).returns(cached)

    # check that the actions are not expired
    @controller.expects(:expire_action).never

    # just update the cache time stamp
    Rails.cache.expects(:write).with(RepositoriesController::CACHE_ID, current_time)

    get :index
  end


end
