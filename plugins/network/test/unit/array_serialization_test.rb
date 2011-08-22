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

class ArraySerializationTest < Test::Unit::TestCase

  def setup
    @options = {:skip_instruct => true, :indent => 0}
  end

  def test_string_array
    a = ["foo", "bar"]
    assert_equal "<strings type=\"array\"><string>foo</string><string>bar</string></strings>", a.to_xml(@options)
  end

  # avoid <nil-classes>
  def test_empty_array_of_strings
    a = []
    assert_equal "<strings type=\"array\"/>", a.to_xml(@options.merge(:root => "strings"))
  end

  # to make karmi happy ;-)
  def test_array_of_empty_strings
    a = ["", ""]
    assert_equal "<strings type=\"array\"><string></string><string></string></strings>", a.to_xml(@options)
  end

  # numbers still fail but we don't care
end
