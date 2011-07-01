#--
# Webyast framework
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

#
# Testing RestdocController
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'mocha'

class RestdocControllerTest < ActionController::TestCase

  def setup
  end

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end

  def test_index
    Restdoc.expects(:find).with(:all).returns(["controller/restdoc/index.html"])
    get :index

    assert_response :success
    assert_match /href="controller\/restdoc\/index.html"/, @response.body
  end

  def test_empty_index
    Restdoc.expects(:find).with(:all).returns([])
    get :index

    assert_response :success
    assert_match /No REST documentation available./, @response.body
  end

end
