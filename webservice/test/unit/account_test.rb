#
# Tests for the Account model
#
require File.join(File.dirname(__FILE__),"..", "test_helper")

class AccountTest < ActiveSupport::TestCase
  fixtures :accounts
  
  def setup
    # see lib/session.rb, used by app/models/account.rb
    Session::Sh.any_instance.stubs(:execute).returns(nil)
    Session::Sh.any_instance.stubs(:get_status).returns(0)
  end
  
  test "bad character in login" do
    assert_equal false, Account.unix2_chkpwd("'", nil)
    assert_equal false, Account.unix2_chkpwd("\\", nil)
  end
  
  test "unix2_chkpwd" do
    @login = "test_user"
    @cmd = "/sbin/unix2_chkpwd rpam '#{@login}'"
    @passwd = "secret"
    Session::Sh.any_instance.stubs(:execute).with(){ |cmd,hash| assert_equal @cmd, cmd ; assert_equal @passwd, hash[:stdin] }.returns(nil)
    Session::Sh.any_instance.stubs(:get_status).returns(0)
    assert Account.unix2_chkpwd(@login, @passwd)
  end
end
