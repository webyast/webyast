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

class LangController < ApplicationController
end

class LangControllerTest < ActionController::TestCase

  def setup
    @controller = LangController.new
  end

  def test_known_lang
    @controller.locale.stubs(:language).returns("es")
    assert_equal "es",@controller.current_locale
  end

  def test_unsuported_lang
    @controller.locale.stubs(:language).returns("af") #af is not supported now
    assert_equal "en_US",@controller.current_locale
  end

  def test_browser_lang
    @controller.locale.stubs(:language).returns("zh-cn")
    assert_equal "zh_CN",@controller.current_locale
  end

end
