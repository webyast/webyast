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

require 'test_helper'
require 'string_serialization'

# a stupid modification to see if passing a special builder works
class MyBuilder < Builder::XmlMarkup
  def tag! name, content
    super "my#{name}", content
  end
end

class StringSerializationTest < Test::Unit::TestCase

  def setup
    @options = {:skip_instruct => true}
  end

  def test_plain
    assert_equal "<string>foo</string>", "foo".to_xml(@options)
  end

  def test_full
    assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?><string>foo</string>", "foo".to_xml
  end

  def test_escaping
    assert_equal "<string>&amp;</string>", "&".to_xml(@options)
  end

  def test_special_builder
    my_builder = MyBuilder.new()
    assert_equal "<mystring>foo</mystring>", "foo".to_xml(@options.merge(:builder => my_builder))
  end

end
