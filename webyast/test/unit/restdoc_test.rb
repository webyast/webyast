#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

require File.dirname(__FILE__) + '/../test_helper'

class RestdocTest < ActiveSupport::TestCase

  def setup
    @dummy_path = 'dummy/plugin/path'
    Rails.configuration.stubs(:plugin_paths).returns(@dummy_path)
    Dir.stubs(:'[]').with("#{@dummy_path}/*").returns(["#{@dummy_path}/dummy_plugin"])
    File.stubs(:directory?).with("#{@dummy_path}/dummy_plugin/app").returns(true)
    File.stubs(:directory?).with("#{@dummy_path}/dummy_plugin/public").returns(true)
    Dir.stubs(:'[]').with("#{@dummy_path}/dummy_plugin/public/**/restdoc/index.html").returns(
      ["#{@dummy_path}/dummy_plugin/public/controller/restdoc/index.html"])
    File.stubs(:file?).with("#{@dummy_path}/dummy_plugin/public/controller/restdoc/index.html").returns(true)
  end

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end

  def test_find
    r = Restdoc.find :all

    assert_equal ["controller/restdoc/index.html"], r
  end

  def test_find_nothing
    Dir.stubs(:'[]').with("#{@dummy_path}/dummy_plugin/public/**/restdoc/index.html").returns([])

    r = Restdoc.find :all

    assert_equal [], r
  end
end