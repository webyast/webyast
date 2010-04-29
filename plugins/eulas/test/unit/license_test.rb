#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class LicenseTest < ActiveSupport::TestCase
YAML_CONTENT = <<EOF
licenses:
  - openSUSE-11.1
  - SLES-11
EOF

  def setup
    License.const_set 'RESOURCES_DIR', File.join(File.dirname(__FILE__),"..","..","test","share")
    License.const_set 'VAR_DIR'      , File.join(File.dirname(__FILE__),"..","..","test","var")
    YaST::ConfigFile.stubs(:read_file).returns(YAML_CONTENT)
    YaST::ConfigFile.any_instance.stubs(:path).returns(__FILE__)

  end

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
    assert_equal( license.name, 'SLES-11')
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
    assert_equal(licenses[1].name, 'SLES-11')
    assert_nil licenses[1].text 
    assert_not_nil licenses.to_xml
    assert_not_nil licenses.to_json
  end

  def text_all_accepted
    assert_false( License.all_accepted? )
  end

end
