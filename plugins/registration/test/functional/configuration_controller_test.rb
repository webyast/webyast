require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )
module Registration
class ConfigurationControllerTest < ActionController::TestCase
  fixtures :accounts

    DATA = {'server'=>{'url'=>'https://somewhere.else.com/center/regsvc'},
            'certificate'=>{'data'=>"<![CDATA[-----BEGIN CERTIFICATE-----MIIFIDCCBAigAwIBAgIJAPP6cY6saTFlMA0GCSqGSIb3DQEBBQUAMIGPMQswCQYDVQQGEwJERTEPMA0    .........     60QTef32lxeuVH9Kve8gGZiMwDqcJflJ8NLO3kNW3Zys2p4agg22yttmUs=-----END CERTIFICATE-----"}}

  def setup
    @data = DATA
#    @model_class = Registration

#    @reg = Registration.new
#    @reg.config = DATA
    
#    Registration.stubs(:find).returns(@reg)

#    @controller = Registration::ConfigurationController.new
#    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA
  end  

#  include PluginBasicTests
  
  def test_update
#    mock_save #Fixme as when the interface is ready
#    @controller = Registration::ConfigurationController.new
#    put :update ,  DATA
#    assert_response :success
  end


end
end
