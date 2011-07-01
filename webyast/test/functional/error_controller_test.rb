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

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

# a message with invalid HTML/XML string (needs to be escaped)
TEST_MESSAGE = '>&<"'
TEST_RESPONSE = 404

class ErrorControllerTest < ActionController::TestCase

  # html_escape is used here
  include ERB::Util

  class ErrorController < ApplicationController
    def error
      render ErrorResult.error(TEST_RESPONSE, 1, TEST_MESSAGE) and return
    end
  end

  def setup
    @controller = ErrorController.new
    @routes = ActionController::Routing::Routes.routes.dup
    # add a catch-all route for the tests only.
    ActionController::Routing::Routes.draw {
      |map| map.connect ':controller/:action'
    }
  end

  def teardown
    #restore original routes to not affect other tests
    ActionController::Routing::Routes.routes = @routes
  end

  # test escaping in XML error message body
  def test_error_xml
    mime = Mime::XML
    @request.accept = mime.to_s

    get :error, :format => :xml

    assert_response TEST_RESPONSE
    assert_equal mime.to_s, @response.content_type

    # the XML parsing must succeed here
    ret = Hash.from_xml @response.body
    # check the result, it must be the same after parsing from XML
    assert_equal TEST_MESSAGE, ret['error']['message']
  end

  # test escaping in HTML error message
  def test_error_html
    get :error
    assert_response TEST_RESPONSE

    # check whether the result contains the expected escaped string
    expected = html_escape TEST_MESSAGE
    assert @response.body.index(expected) > 0
  end

end
