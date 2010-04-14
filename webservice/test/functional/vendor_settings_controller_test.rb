require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class VendorSettingsControllerTest < ActionController::TestCase
  def setup
    YaST::ConfigFile.stubs(:read_file).returns( 
        File.read File.join(File.dirname(__FILE__),"..","resource_fixtures","vendor.yml")
      )
  end

  def test_index
   get :index, :format => "xml"
   assert_response :success
   response = Hash.from_xml @response.body
   assert_equal 4, response["vendor_settings"].size
  end

  def test_show
   get :show, :format => "xml", :id=>"bug_url"
   assert_response :success
   response = Hash.from_xml @response.body
   assert_equal "http://www.mycompany.com/report_bug", response["vendor_setting"]["value"]
  end
  
end
