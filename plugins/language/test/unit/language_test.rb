require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  def setup
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "list"]).returns({:exit=>0, :stdout=>"", :stderr=>"af_ZA (Afrikaans)\nar_EG (Arabic)\nbg_BG (Bulgarian)\nbn_BD (Bengali)\nbs_BA (Bosanski)\nca_ES (Catala)\ncs_CZ (Cestina)\ncy_GB (Cymraeg)\nda_DK (Dansk)\nde_DE (Deutsch)\nel_GR (Greek)\nen_GB (English (UK))\nen_US (English (US))\nes_ES (Espanol)\net_EE (Eesti)\nfi_FI (Suomi)\nfr_FR (Francais)\ngl_ES (Galego)\ngu_IN (Gujarati)\nhe_IL (Ivrit)\nhi_IN (Hindi)\nhr_HR (Hrvatski)\nhu_HU (Magyar)\nid_ID (Bahasa Indonesia)\nit_IT (Italiano)\nja_JP (Japanese)\nka_GE (Kartuli)\nkm_KH (Khmer)\nko_KR (Korean)\nlt_LT (Lithuanian)\nmk_MK (Makedonski)\nmr_IN (Marathi)\nnb_NO (Norsk)\nnl_NL (Nederlands)\nnn_NO (Nynorsk)\npa_IN (Punjabi)\npl_PL (Polski)\npt_BR (Portugues brasileiro)\npt_PT (Portugues)\nro_RO (Romana)\nru_RU (Russian)\nsi_LK (Sinhala)\nsk_SK (Slovencina)\nsl_SI (Slovenscina)\nsr_RS (Srpski)\nsv_SE (Svenska)\nta_IN (Tamil)\nth_TH (phasa thai)\ntr_TR (Turkce)\nuk_UA (Ukrainian)\nvi_VN (Vietnamese)\nwa_BE (Walon)\nxh_ZA (isiXhosa)\nzh_CN (Simplified Chinese)\nzh_TW (Traditional Chinese (Taiwan))\nzu_ZA (isiZulu)\n"})
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2", "language", "summary"]).returns({:exit=>0, :stdout=>"", :stderr=>"Current Language: de_DE (Deutsch)\nAdditional Languages: en_US\n"})
    @language = Language.new
    @language.read
  end
  
  def test_available
    assert_equal(56, @language.available.split("\n").size)
  end

  def test_first_language
    assert_equal("de_DE", @language.first_language)
  end

  def test_second_languages
    assert_equal("en_US", @language.second_languages)
  end


end
