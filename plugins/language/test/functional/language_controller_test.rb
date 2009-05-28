require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class LanguageControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = LanguageController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "list"]).returns({:exit=>0, :stdout=>"", :stderr=>"af_ZA (Afrikaans)\nar_EG (Arabic)\nbg_BG (Bulgarian)\nbn_BD (Bengali)\nbs_BA (Bosanski)\nca_ES (Catala)\ncs_CZ (Cestina)\ncy_GB (Cymraeg)\nda_DK (Dansk)\nde_DE (Deutsch)\nel_GR (Greek)\nen_GB (English (UK))\nen_US (English (US))\nes_ES (Espanol)\net_EE (Eesti)\nfi_FI (Suomi)\nfr_FR (Francais)\ngl_ES (Galego)\ngu_IN (Gujarati)\nhe_IL (Ivrit)\nhi_IN (Hindi)\nhr_HR (Hrvatski)\nhu_HU (Magyar)\nid_ID (Bahasa Indonesia)\nit_IT (Italiano)\nja_JP (Japanese)\nka_GE (Kartuli)\nkm_KH (Khmer)\nko_KR (Korean)\nlt_LT (Lithuanian)\nmk_MK (Makedonski)\nmr_IN (Marathi)\nnb_NO (Norsk)\nnl_NL (Nederlands)\nnn_NO (Nynorsk)\npa_IN (Punjabi)\npl_PL (Polski)\npt_BR (Portugues brasileiro)\npt_PT (Portugues)\nro_RO (Romana)\nru_RU (Russian)\nsi_LK (Sinhala)\nsk_SK (Slovencina)\nsl_SI (Slovenscina)\nsr_RS (Srpski)\nsv_SE (Svenska)\nta_IN (Tamil)\nth_TH (phasa thai)\ntr_TR (Turkce)\nuk_UA (Ukrainian)\nvi_VN (Vietnamese)\nwa_BE (Walon)\nxh_ZA (isiXhosa)\nzh_CN (Simplified Chinese)\nzh_TW (Traditional Chinese (Taiwan))\nzu_ZA (isiZulu)\n"})
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "summary"]).returns({:exit=>0, :stdout=>"", :stderr=>"Current Language: de_DE (Deutsch)\nAdditional Languages: en_US\n"})
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
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "list"]).returns({:exit=>2, :stdout=>"", :stderr=>"wrong parameter"})
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "summary"]).returns({:exit=>2, :stdout=>"", :stderr=>"wrong parameter"})
    get :show
    assert_response :success
  end

  test "access show with a SCR call which returns nil" do
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "list"]).returns()
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "summary"]).returns()
    get :show
    assert_response :success
  end

  test "writing values back" do
    Scr.any_instance.stubs(:initialize)

    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "set",  "lang=de_DE", "no_packages"]).returns()
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "set",  "languages=en_US", "no_packages"]).returns()

    post :create, :language=>{"available"=>[], "first_language"=>"de_DE", "second_languages"=>[{"id"=>"en_US"}]}
    assert_response :success
  end

  test "writing values back with not existing parameters" do
    post :create
    assert_response 404
  end

  test "writing values back with wrong parameters" do
    post :create, :language=>{"available"=>[]}
    assert_response 404
  end


end
