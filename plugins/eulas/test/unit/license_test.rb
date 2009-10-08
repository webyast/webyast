require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class LicenseTest < ActiveSupport::TestCase
  def test_create
    license = License.find 1
    assert_not_nil license
    assert_equal( license.accepted, false)
    assert_equal( license.name, 'openSUSE-11.1' )
  end

  def test_accepted
    license = License.find 2
    assert_not_nil license
    assert_equal( license.accepted, true)
    assert_equal( license.name, 'SLED-10-SP3')
  end

  def test_load_text
    license = License.find 1
    license.load_text 'de'
    assert_not_nil license.text
    assert_equal( license.text_lang, 'de')
    license.load_text 'xyz'
    assert_not_nil license.text
    assert_equal(license.text_lang, 'en')
  end

  def test_to_xml
    license = License.find 1
    license.load_text 'de'
    assert_not_nil license.to_xml
  end

  def test_to_json
    license = License.find 1
    license.load_text 'de'
    assert_not_nil license.to_json
  end

  def test_find_all
    licenses = License.find_all 
    assert_equal( licenses.length, 2)
    assert_equal(licenses[1].name, 'SLED-10-SP3')
    assert_nil licenses[1].text 
    assert_not_nil licenses.to_xml
    assert_not_nil licenses.to_json
  end

end
