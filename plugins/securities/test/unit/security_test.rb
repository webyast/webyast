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
    Scr.instance.stubs(:execute).with(["/usr/sbin/rcsshd", "status"]).
                        returns(:stdout => "Checking for service sshd running")
    Scr.instance.stubs(:execute).with(["/sbin/yast2", "firewall", "startup",
                         "show"]).returns(:stderr => "Start-Up: \n --------- \n
                                      Firewall is enabled in the boot process")

    sec = Security.new
    assert sec.firewall?, "firewall returned false instead of true"
    assert sec.firewall_after_startup?, "firewall_after_startup returned false instead of true"
    assert sec.ssh?, "ssh returned false instead of true"
  end

  def test_methods_return_false
    Scr.instance.stubs(:execute).with(["/sbin/rcSuSEfirewall2", "status"]).
              returns(:stdout => "Checking the status of SuSEfirewall2 unused")
    Scr.instance.stubs(:execute).with(["/usr/sbin/rcsshd", "status"]).
                         returns(:stdout => "Checking for service sshd unused")
    Scr.instance.stubs(:execute).with(["/sbin/yast2", "firewall", "startup",
                         "show"]).returns(:stderr => "Start-Up: \n --------- \n
                                               Firewall needs manual starting")

    sec = Security.new
    assert !sec.firewall?, "firewall returned true instead of false"
    assert !sec.firewall_after_startup?, "firewall_after_startup returned true instead of false"
    assert !sec.ssh?, "ssh returned true instead of false"
  end

  def test_methods_set_params
    Scr.instance.stubs(:execute).with(["/sbin/rcSuSEfirewall2", "restart"]).
                          returns(:stdout => "Starting Firewall Initialization
                                                         (phase 2 of 2) done")
    Scr.instance.stubs(:execute).with(["/usr/sbin/rcsshd", "restart"]).
                          returns(:stdout => "Starting SSH daemon done")
    Scr.instance.stubs(:execute).with(["/sbin/yast2", "firewall", "startup",
                         "atboot"]).returns(:stderr => "Start-Up: \n ---------
                               \n\n Enabling firewall in the boot process...")
    Scr.instance.stubs(:execute).with(["/sbin/rcSuSEfirewall2", "stop"]).
                         returns(:stdout => "Shutting down the Firewall done")
    Scr.instance.stubs(:execute).with(["/usr/sbin/rcsshd", "stop"]).
                           returns(:stdout => "Shutting down SSH daemon done")
    Scr.instance.stubs(:execute).with(["/sbin/yast2", "firewall", "startup",
                         "manual"]).returns(:stderr => "Start-Up: \n ---------
                             \n\n Removing firewall from the boot process...")

    sec = Security.new
    assert sec.firewall(true), "firewall returned false instead of true"
    assert sec.ssh(true), "ssh returned false instead of true"
    assert sec.firewall_after_startup(true), "firewall_after_startup returned false instead of true"
    assert !sec.firewall(false), "firewall returned true instead of false"
    assert !sec.ssh(false), "ssh returned true instead of false"
    assert !sec.firewall_after_startup(false), "firewall_after_startup returned true instead of false"
  end

end
