require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class SystemtimesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = SystemtimesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "timezone", "list"]).returns({:stderr=>"\nRegion: Africa\nAfrica/Abidjan (Abidjan)\nAfrica/Accra (Accra)\nAfrica/Addis_Ababa (Addis Ababa)\nAfrica/Algiers (Algiers)\nAfrica/Asmara (Asmara)\nAfrica/Bamako (Bamako)\nAfrica/Bangui (Bangui)\nAfrica/Banjul (Banjul)\nAfrica/Bissau (Bissau)\nAfrica/Blantyre (Blantyre)\nAfrica/Brazzaville (Brazzaville)\nAfrica/Bujumbura (Bujumbura)\nAfrica/Cairo (Cairo)\nAfrica/Casablanca (Casablanca)\nAfrica/Ceuta (Ceuta)\nAfrica/Conakry (Conakry)\n", :exit=>0, :stdout=>""})
    Scr.any_instance.stubs(:execute).with(["/bin/date"]).returns({:stderr=>"", :exit=>0, :stdout=>"Fri May 29 10:37:28 CEST 2009\n"})
    Scr.any_instance.stubs(:read).with(".sysconfig.clock.TIMEZONE").returns("Europe/Berlin")
    Scr.any_instance.stubs(:read).with(".sysconfig.clock.HWCLOCK").returns("-u")
  end

  test "access show" do
    get :show
    assert_response :success
  end

  test "access show xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :format => :xml
    assert_equal mime.to_s, @response.content_type
  end

  test "access show json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  test "access show with a SCR call which returns an error" do
    Scr.any_instance.stubs(:execute).with(["/bin/date"]).returns({:stderr=>"", :exit=>1, :stdout=>"Fri May 29 10:37:28 CEST 2009\n"})
    get :show
    assert_response 404
  end

  test "access show with a SCR call which returns nil" do
    Scr.any_instance.stubs(:read).with(".sysconfig.clock.HWCLOCK").returns(nil)
    get :show
    assert_response 404
  end

  test "writing values back" do
    Scr.any_instance.stubs(:execute).with(["/sbin/hwclock", "--set", "-u", "--date=\"05/29/09 04:49:00\""], ["TZ=Europe/Berlin"]).returns()
    Scr.any_instance.stubs(:execute).with(['/sbin/hwclock', '--hctosys', '-u']).returns()
    Scr.any_instance.stubs(:write).with(".sysconfig.clock.TIMEZONE","Europe/Berlin").returns()
    Scr.any_instance.stubs(:write).with(".sysconfig.clock.HWCLOCK","-u").returns()
    current_time = Time.parse("Fri May 29 04:49:00 UTC 2009").strftime("%H:%M:%S")
    date = Time.parse("Fri May 29 04:49:00 UTC 2009").strftime("%m/%d/%y")
    post :create, :time=>{"timezone"=>"Europe/Berlin", "is_utc"=>true, "currenttime"=>current_time, "date"=>date, "validtimezones"=>[]}
    assert_response :success
  end

  test "writing values back with not existing parameters" do
    post :create
    assert_response 404
  end

  test "writing values back with wrong parameters" do
    post :create, :time=>{}
    assert_response 404
  end

end
