require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class ConfigurationControllerTest < ActionController::TestCase
  fixtures :accounts

    DATA = {'server'=>{'url'=>'https://somewhere.else.com/center/regsvc'},
            'certificate'=>{'data'=>"<![CDATA[-----BEGIN CERTIFICATE-----MIIFIDCCBAigAwIBAgIJAPP6cY6saTFlMA0GCSqGSIb3DQEBBQUAMIGPMQswCQYDVQQGEwJERTEPMA0    .........     60QTef32lxeuVH9Kve8gGZiMwDqcJflJ8NLO3kNW3Zys2p4agg22yttmUs=-----END CERTIFICATE-----"}}

  def setup
    @model_class = Registration
    
#    Registration.stubs(:find).returns(Registration.new)

    @controller = ConfigurationController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA
  end  

#  include PluginBasicTests
  
  def test_update
#    mock_save #Fixme as when the interface is ready
#    put :update, DATA
#    assert_response :success
  end


end
