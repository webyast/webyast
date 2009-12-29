require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class StatusControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @model_class = Status

    Status.any_instance.stubs(:check_collectd).returns(true)
    Status.any_instance.stubs(:datapath).returns("/var/lib/collectd/test")

    expected_response = {"tx"=>
  {"1248092580"=>"4.3878571429e+01",
   "1248092790"=>"4.0714285714e+00",
   "1248092440"=>"4.0992857143e+01",
   "1248093000"=>"1.5542857143e+01",
   "1248092650"=>"9.7942857143e+01",
   "1248092860"=>"2.4142857143e+00",
   "1248092300"=>"4.0500000000e+00",
   "1248092510"=>"3.4264285714e+01",
   "1248093070"=>"2.7071428571e+00",
   "1248092720"=>"2.9928571429e+00",
   "1248092930"=>"2.8285714286e+00",
   "1248092370"=>"2.1435714286e+01"},
 "rx"=>
  {"1248092580"=>"7.7485714286e+01",
   "1248093140"=>"invalid",
   "1248092790"=>"2.2585714286e+01",
   "1248092230"=>"invalid",
   "1248092440"=>"5.7578571429e+01",
   "1248093000"=>"3.1314285714e+01",
   "1248092650"=>"1.1698571429e+02",
   "1248092860"=>"2.4292857143e+01",
   "1248092090"=>"invalid",
   "1248092300"=>"2.4628571429e+01",
   "1248092510"=>"4.9271428571e+01",
   "1248093070"=>"2.3064285714e+01",
   "1248092720"=>"2.3042857143e+01",
   "1248092930"=>"2.5092857143e+01",
   "1248092160"=>"invalid",
   "1248092370"=>"4.7314285714e+01"},
 "starttime"=>"1248092090"}

    Status.any_instance.stubs(:fetch_metric).returns(expected_response)

    Status.stubs(:find).returns([Status.new, Status.new])

    @controller = StatusController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end

  include PluginBasicTests

  # background request requires at least 'stop' parameter
  def test_backround_mode_missing_param
    get :show, { :background => true }
    assert_response 422
  end

  def test_backround_mode_param_ok
    get :show, { :background => true, :stop => 1248092370 }
    assert_response :success
  end


  def test_update_noparams
    # nothing
  end

  def test_update_noperm
    # nothing
  end

  # FIXME
  def test_access_show_json
    # ActionView::MissingTemplate: Missing template status/show.erb in view path app/views:.
  end
end

