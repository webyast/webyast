# == Brute force Protection class
# === Overview
#
# Singleton class thant remember fail attempts to log to REST-SERVICE.
# After specified time period is failed attemps cleared. 
# 
# === Usage
#
# When user tries to login ensure that it is not blocked by BruteForceProtection.instance.blocked?
# When user failed to login call BruteForceProtection.instance.fail_attempt

class BruteForceProtection
  include Singleton
 
  #Specifies number of failed attempts before block
  ATTEMPTS_TO_BLOCK=10

  #Specifies timeout if user failed to login
  TIMEOUT_ON_FAIL=2

  #Specifies how long is login blocked
  BAN_TIMEOUT=10*60 #10 minutes

  attr_reader :last_fail

  #Sets initial values
  def initialize
    @blocked = false
    @last_fail = Time.new
    @count_failed = 0
  end

  #Returns if login is blocked
  def blocked?
    unless @blocked
      return false
    end

    clean_old_block

    return @blocked
  end

  # notification that user fail to login
  def fail_attempt
    clean_old_block #clean old fail attempts
    @last_fail = Time.new
    @count_failed += 1
    sleep TIMEOUT_ON_FAIL
    @blocked = @count_failed >= ATTEMPTS_TO_BLOCK
  end

  private

  #Cleans failed attempts if specified time pass
  def clean_old_block
    if (Time.new - @last_fail) > BAN_TIMEOUT
      @blocked = false
      @count_failed=0
    end
  end

end
