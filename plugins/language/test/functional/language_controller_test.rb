require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'


class LanguageControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = LanguageController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    YastService.any_instance.stubs(:initialize)
    YastService.any_instance.stubs(:execute).with(["YaPI::LANGUAGE::GetCurrentLanguage"]).returns("en_US")
  end

#  TODO write tests
#  def test_access_show
#    get :show
#    assert_response :success
#  end
#
#  def test_access_show_xml
#    mime = Mime::XML
#    @request.accept = mime.to_s
#    get :show, :format => :xml
#    assert_equal mime.to_s, @response.content_type
#  end
#
#  def test_access_show_json
#    mime = Mime::JSON
#    @request.accept = mime.to_s
#    get :show, :format => :json
#    assert_equal mime.to_s, @response.content_type
#  end

end
