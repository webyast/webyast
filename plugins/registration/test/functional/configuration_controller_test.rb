require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )
module Registration
  class ConfigurationControllerTest < ActionController::TestCase
    fixtures :accounts

    DATA = {'server'=>{'url'=>'https://somewhere.else.com/center/regsvc'},
            'certificate'=>{'data'=>"<![CDATA[-----BEGIN CERTIFICATE-----MIIFIDCCBAigAwIBAgIJAPP6cY6saTFlMA0GCSqGSIb3DQEBBQUAMIGPMQswCQYDVQQGEwJERTEPMA0    .........     60QTef32lxeuVH9Kve8gGZiMwDqcJflJ8NLO3kNW3Zys2p4agg22yttmUs=-----END CERTIFICATE-----"}}

    def setup
      @data = DATA
      @model_class = Register
      @controller = Registration::ConfigurationController.new
      @request = ActionController::TestRequest.new
      # http://railsforum.com/viewtopic.php?id=1719
      @request.session[:account_id] = 1 # defined in fixtures
      @data = DATA
    end  

#    include PluginBasicTests
  
    def test_update
      Register.any_instance.stubs(:save)
#      put :update, DATA
#      assert_response :success
#      reg = assigns(:registration)
#      assert reg
#      assert_equal reg.server, DATA[:server]
#      assert_equal reg.certificate, DATA[:certificate]
    end
  end
end
