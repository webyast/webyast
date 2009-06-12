require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  def setup
    
    @language = Language.new
    
  end

  def test_current_language
    YastService.stubs(:Call).with("YaPI::LANGUAGE::GetCurrentLanguage").returns("en_US")
    @language.fill_language
    assert_equal("en_US", @language.language)
  end

  def test_change_language
    debugger
    YastService.stubs(:Call).with("YaPI::LANGUAGE::SetCurrentLanguage","en_GB").returns(true)
    @language.language="en_GB"
    assert_equal("en_GB", @language.language)
  end


end
