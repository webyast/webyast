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
#require "service"
#require "yast_mock"
require "interface"
require "hostname"
require "dns"
require "route"

require "mocha"

class NetworkControllerTest < ActionController::TestCase
  # return contents of a fixture file +file+
#  def fixture(file)
#    IO.read(File.join(File.dirname(__FILE__), "..", "fixtures", file))
#  end

#  def setup
#    # bypass authentication
#    NetworkController.any_instance.stubs(:login_required)

#    # stub what the REST is supposed to return
#    response_ifcs = fixture "ifcs.xml"
#    response_eth1 = fixture "ifc.xml"
#    response_eth2 = fixture "ifc-dhcp.xml"
#    response_hn = fixture "hostname.xml"
#    response_dns = fixture "dns.xml"
#    response_rt = fixture "routes_default.xml"

#    ActiveResource::HttpMock.set_authentication # ? vs login_required
#    ActiveResource::HttpMock.respond_to do |mock|
#      header = ActiveResource::HttpMock.authentication_header
#      # this is inadequate, :singular is per resource,
#      # and does NOT depend on :policy
#      # see yast-rest-service/plugins/network/config/resources/*
#      mock.resources({
#        :"org.opensuse.yast.modules.yapi.network.dns" => "/network/dns",
#        :"org.opensuse.yast.modules.yapi.network.hostname" => "/network/hostname",    
#        :"org.opensuse.yast.modules.yapi.network.interfaces" => "/network/interfaces",
#        :"org.opensuse.yast.modules.yapi.network.routes" => "/network/routes",
#        }, { :policy => "org.opensuse.yast.modules.yapi.network" })
#      mock.permissions "org.opensuse.yast.modules.yapi.network", { :read => true, :write => true }
#      mock.get  "/network/interfaces.xml", header, response_ifcs, 200
#      mock.get  "/network/interfaces/eth1.xml", header, response_eth1, 200
#      mock.get  "/network/interfaces/eth2.xml", header, response_eth2, 200
#      mock.get  "/network/hostname.xml", header, response_hn, 200
#      mock.get  "/network/dns.xml", header, response_dns, 200
#      mock.get  "/network/routes/default.xml", header, response_rt, 200
#      # no mock.post/put, meaning we expect no saves
#    end
#  end
  
  def fixture(file)
    ret = open(File.join(File.dirname(__FILE__), "..", "fixtures", file)) { |f| YAML.load(f) }
    ret
  end
  
  def setup
    @controller = NetworkController.new
    @request = ActionController::TestRequest.new
    @request.session[:account_id] = 1 
    
    @interfaces = fixture "interfaces.yaml"
    @eth0 = fixture "eth0.yaml"
    @hostname = fixture "hostname.yaml"
    
    @dns = fixture "dns.yaml"
    @route = fixture "route.yaml"
    
    NetworkController.any_instance.stubs(:login_required)
  end
  
  
  def fake_permissions
    puts "FAKE PERMISSIONS"
    NetworkController.any_instance.stubs(:yapi_perm_check).with("network.read")
    NetworkController.any_instance.stubs(:yapi_perm_granted?).with("network.read")
    NetworkController.any_instance.stubs(:yapi_perm_check).with("network.write")
    NetworkController.any_instance.stubs(:yapi_perm_granted?).with("network.write")
  end
  
  def stabs_functions
    puts "Stub actions"
    #@ifcs = Interface.find :all
    Interface.stubs(:find).with(:all).returns(@interfaces)
    #ifc = Interface.find(id)
    Interface.stubs(:find).with("eth0").returns(@eth0)
    
    #hn = Hostname.find 
    Hostname.stubs(:find).returns(@hostname)
    
    #dns = Dns.find 
    Dns.stubs(:find).returns(@dns)
    
    #rt = Route.find "default"
    Route.stubs(:find).with("default").returns(@route)
  end
  
  test "access index html" do
    fake_permissions
    stabs_functions
    
    mime = Mime::HTML
    @request.accept = mime.to_s

    get :index, :format => "html"
    assert_response :success
    assert_valid_markup
    assert_equal mime.to_s, @response.content_type
  end
  
#  # "TRUE" if service exist and "FALSE" for nonexistent service
#  def service_exist(service)
#    if service
#      Service.any_instance.stubs(:read_status).with({"custom" => false}).returns(@status)
#    else
#      Service.any_instance.stubs(:read_status).with({"custom" => false}).returns(@status_unknown)
#    end
#  end

#  def teardown
#    ActiveResource::HttpMock.reset!
#  end

#  def test_should_show_it
#    get :index
#    assert_response :success
#    assert_valid_markup
#    # test just the last assignment, for brevity
#    assert_not_nil assigns(:default_route)
#    assert_not_nil assigns(:name)
#  end

#  def test_with_dhcp
#    get :index, :interface => "eth2"
#    assert_response :success
#    assert_valid_markup
#    # test just the last assignment, for brevity
#    assert_not_nil assigns(:default_route)
#    assert_not_nil assigns(:name)
#  end

#  def test_dhcp_without_change
#    put :update, { :interface => "eth2", :conf_mode => "dhcp", :default_route => "192.168.1.1", :nameservers => "192.168.1.2 192.168.1.42", :searchdomains => "labs.example.com example.com", :hostname => "arthur", :domain => "britons" }
#    assert_response :redirect
#    assert_redirected_to :controller => "controlpanel", :action => "index"
#  end

#  # TODO also test the case in sample appliance (dhcp-only)
end
