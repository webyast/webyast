#
# Test login
#

$:.unshift "../ext/Rpam"
require 'test/unit'
require 'rpam'

class InteractiveTest < Test::Unit::TestCase
  def test_login
    print "User: "
    user = gets.chomp
    print "Password: "
    system("stty -echo")
    pass = gets.chomp
    system("stty echo")
    puts
    assert Rpam::authpam(user,pass)
  end
end
