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
