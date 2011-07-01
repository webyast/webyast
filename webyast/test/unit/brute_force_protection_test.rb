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

require File.join(File.dirname(__FILE__),"..", "test_helper")

class BruteForceProtectionTest < ActiveSupport::TestCase
  
  def setup
    @protection = BruteForceProtection.instance
    @protection.send "initialize"
  end
    
  def test_not_blocking_clean
    assert !@protection.blocked?("test")
  end

  def test_blocked
    BruteForceProtection.const_set "TIMEOUT_ON_FAIL", 0 #disable sleep
    (BruteForceProtection.const_get "ATTEMPTS_TO_BLOCK").times do
      @protection.fail_attempt "test"
    end
    assert @protection.blocked?("test")
  end

  def test_unblocked_after_period
    BruteForceProtection.const_set "TIMEOUT_ON_FAIL", 0 #disable sleep
    BruteForceProtection::ATTEMPTS_TO_BLOCK.times do
      @protection.fail_attempt "test"
    end
    old_time = Time.now - (BruteForceProtection::BAN_TIMEOUT+10)
    hash = @protection.instance_variable_get :@blocking_list
    hash["test"][:last_fail] = old_time  # simulate old time in counter

    assert !@protection.blocked?("test")
  end

end
