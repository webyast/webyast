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
    raise NoPermissionException.new("org.opensuse.yast.system.status.read",
                                    "schubi")
  end

  def redirect
    redirect_success
  end

  def ensure_logout
    super
  end

  def ensure_login
    super
  end

  def crash_action
    crash
  end

  def url_with_new_port
    render :text => (url_for :port => 50)
  end

  private
    def crash
      raise "exception"
    end
end


class TestControllerTest < ActionController::TestCase


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
    assert_false @response.body.blank?
    assert @response.body.match(/test\.host:50/), "response doesn't contain correct site. response is '#{@response.body}'"
  end

  def test_ensure_logout
    TestController.any_instance.stubs(:logged_in?).returns true
    get :ensure_logout
    assert_response :redirect
    assert_redirected_to "/"
    assert flash
  end

  def test_ensure_logout
    TestController.any_instance.stubs(:logged_in?).returns false
    get :ensure_login
    assert_response :redirect
    assert_redirected_to "/session/new"
    assert flash
  end
  
  def test_success_redirect_nonwizard
    Basesystem.stubs(:installed?).returns(true)
    get :redirect
    assert_response :redirect
    assert_redirected_to "/controlpanel"
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
    assert_redirected_to "/controlpanel"
    assert flash
  end

  #
  # bnc#581250
  #
  
  test "redirect after succesful save" do
  end
  
  # it is critical, because in exception trap should not never raise another exception!!!
  test "exception traps" do
  end
  
  test "vendor extension for locale" do
  end
  
  test "locale if domain is not specified" do
  end
  
  test "vendor bugzilla" do
    YaST::ConfigFile.stubs(:read_file).returns( 
        File.read File.join(File.dirname(__FILE__),"..",
                  "resource_fixtures",
                  "vendor.yml"))

    get :crash_action
    assert_response 500
    assert @response.body.include? "WebYaST" #test if response is not rails handler but our styled one
    Rails.logger.debug @response.body
    assert @response.body.include?("www.mycompany.com"), "vendor bugzilla URL is not used" #test if points to vendor bugzilla
  end
  
  test "locale loading" do
  end
  
end
