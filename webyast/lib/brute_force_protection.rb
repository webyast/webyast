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

  #Sets initial values
  def initialize
    @blocking_list = {}
  end

  #Returns if login is blocked
  def blocked?(user)
    clean_old_block

    return (@blocking_list[user] && @blocking_list[user][:blocked])
  end

  def last_failed(user)
    return 0 unless @blocking_list[user]
    return @blocking_list[user][:last_fail]
  end

  # notification that user fail to login
  def fail_attempt (user)
    clean_old_block #clean old fail attempts
    if @blocking_list[user]
      record = @blocking_list[user]
      record[:last_fail] = Time.now
      record[:count] += 1
      record[:blocked] = record[:count] >= ATTEMPTS_TO_BLOCK
    else
      @blocking_list[user] = {
        :last_fail => Time.now,
        :count => 1,
        :blocked => ATTEMPTS_TO_BLOCK == 1
      }
    end
    
    sleep TIMEOUT_ON_FAIL #FIXME maybe unix_chkpwd is slow enought to disable sleep
  end

  private

  #Cleans failed attempts if specified time pass
  def clean_old_block
    @blocking_list.each_value {
      |value|
      if (Time.now - value[:last_fail]) > BAN_TIMEOUT
        value[:blocked] = false
        value[:count] = 0
      end
    }
  end

end
