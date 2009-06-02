require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'scr'
require 'mocha'
require 'test_helper'

class SecurityTest < ActiveSupport::TestCase
#  fixtures :accounts
  def setup
#    @controller = SecuritiesController.new
#    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
  end

  def test_methods_return_true
    Scr.instance.stubs(:execute).with(["/sbin/rcSuSEfirewall2", "status"]).
             returns(:stdout => "Checking the status of SuSEfirewall2 running")
    Scr.instance.stubs(:execute).with(["/usr/sbin/sshd", "status"]).
                        returns(:stdout => "Checking for service sshd running")
    Scr.instance.stubs(:execute).with(["/sbin/yast2", "firewall", "startup", "
                          show"]).returns(:stdout => "Start-Up: \n --------- \n
                                      Firewall is enabled in the boot process")
    sec = Security.new
    methods = %w{sec.firewall? sec.firewall_after_startup? sec.ssh?}
    methods.each do |m|
      assert(m, "#{m} returned 'false' instead of 'true'")
    end
  end

  def test_methods_return_false
    Scr.instance.stubs(:execute).with(["/sbin/rcSuSEfirewall2", "status"]).
              returns(:stdout => "Checking the status of SuSEfirewall2 unused")
    Scr.instance.stubs(:execute).with(["/usr/sbin/sshd", "status"]).
                         returns(:stdout => "Checking for service sshd unused")
    Scr.instance.stubs(:execute).with(["/sbin/yast2", "firewall", "startup
                      ", "show"]).returns(:stdout => "Start-Up: \n --------- \n
                                               Firewall needs manual starting")
    sec = Security.new
    methods = %w{!sec.firewall? !sec.firewall_after_startup? !sec.ssh?}
    methods.each do |m|
      assert(m, "#{m} returned 'true' instead of 'false'")
    end
  end

  def test_methods_set_params_true
    Scr.instance.stubs(:execute).with(["/sbin/rcSuSEfirewall2", "start"]).
                          returns(:stdout => "Starting Firewall Initialization
                                                         (phase 2 of 2) done")
    sec = Security.new
    methods = %w{sec.firewall("true") sec.firewall_after_startup("true") sec.ssh("true")}
    methods.each do |m|
      assert_match("true", m)
    end
  end

end
