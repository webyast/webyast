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

class FakeResponse
  attr_reader :message
  attr_reader :code
  attr_reader :body

  def initialize(code, message="")
    @code = code
    @message = message
    @body = message
  end
end

# create a testing controller,
# defining an ApplicationControllerTest class doesn't work
class TestController < ApplicationController
  include Mocha::API

#for test protected method details
  def testing_details(msg,options={})
    details msg,options
  end

  def no_permission
    raise CanCan::AccessDenied.new()
  end

  def redirect
    redirect_success
  end

  def crash_action
    crash
  end

  def url_with_new_port
    render :text => (url_for :port => 50)
  end

  private
    def crash
      raise "Exeption"
    end

end

require File.dirname(__FILE__) + '/../devise_helper'

class TestControllerTest < ActionController::TestCase
  def setup
    devise_sign_in(ControlpanelController) # authenticate user/account
  end

  DETAILS_PREFIX = '<br><a href="#" onClick="$(\'.details\',this.parentNode.parentNode.parentNode).toggle();"><small>details</small></a><pre class="details" style="display:none">'
  DETAILS_SUFFIX = '</pre>'
  TEST_DETAILS_STR = "my wonderfull details <br>&nbsp;"
  TEST_DETAILS_RESULT = DETAILS_PREFIX+'my wonderfull details &lt;br&gt;&amp;nbsp;'+DETAILS_SUFFIX

  def test_details
    controller = TestController.new
    assert_equal (DETAILS_PREFIX+"lest"+DETAILS_SUFFIX).gsub(/\s/,''), controller.testing_details("lest").gsub(/\s/,'')
    assert_equal TEST_DETAILS_RESULT.gsub(/\s/,''), controller.testing_details(TEST_DETAILS_STR).gsub(/\s/,'') #test if result is expected except whitespace (which is ignored in html)
  end

  def test_url_rewrite
    @request.port = 3000
    get :url_with_new_port
    assert !@response.body.blank?
    assert @response.body.match(/test\.host:50/), "response doesn't contain correct site. response is '#{@response.body}'"
  end

  def test_success_redirect_nonwizard
    Basesystem.stubs(:installed?).returns(true)
    get :redirect
    assert_response :redirect
    assert_redirected_to "/controlpanel/index"
  end

  def test_success_redirect_wizard
    Basesystem.stubs(:installed?).returns(true)
    Basesystem.any_instance.stubs(:in_process?).returns(true)
    get :redirect
    assert_response :redirect
    assert_redirected_to "/controlpanel/nextstep?done=test"
  end

  def test_exception_trap_common
    get :crash_action
    assert_response 500
    assert @response.body.include? "WebYaST" #test if response is not rails handler but our styled one
    assert @response.body.include? "bugzilla.novell.com" #test if points to our bugzilla
  end

  def test_exception_trap_no_permission
    get :no_permission
    assert_response :redirect
    assert_redirected_to "/controlpanel/index"
    assert flash
  end

  test "vendor bugzilla" do
    YaST::ConfigFile.stubs(:read_file).returns(File.read File.join(File.dirname(__FILE__),"..", "resource_fixtures", "vendor.yml"))
    get :crash_action
    assert_response 500
    assert @response.body.include? "WebYaST" #test if response is not rails handler but our styled one
    assert @response.body.include?("www.mycompany.com"), "vendor bugzilla URL is not used" #test if points to vendor bugzilla
  end

end
