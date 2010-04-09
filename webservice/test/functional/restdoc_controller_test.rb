#
# Testing RestdocController
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'mocha'

class RestdocControllerTest < ActionController::TestCase

  def setup
  end

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end

  def test_index
    Restdoc.expects(:find).with(:all).returns(["controller/restdoc/index.html"])
    get :index

    assert_response :success
    assert_match /href="controller\/restdoc\/index.html"/, @response.body
  end

  def test_empty_index
    Restdoc.expects(:find).with(:all).returns([])
    get :index

    assert_response :success
    assert_match /No REST documentation available./, @response.body
  end

end
