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

# Group model, YastModel based
class GetentPasswd < BaseModel::Base
  attr_reader :login
  attr_reader :full_name

  def self.find
    result = []
    res = pure_getent
    raise "cannot obtain passwd" unless res
    minimum = system_minimum
    minimum = 1000 if minimum == 0 #fallback
    lines = res.split "\n"
    lines.each do |l|
      elements = l.split ":"
      if elements[2].to_i >= minimum &&
        elements[0] != "nobody" #bnc#632326
        result << GetentPasswd.new(:login => elements[0], :full_name => elements[4])
      end
    end
    active_directory_users = pure_wbinfo
    if $?
      lines = active_directory_users.split "\n"
      lines.each do |l|
        l.chomp!
        result << GetentPasswd.new(:login => l, :full_name => l)
      end
    end
    result
  end

private
  def self.system_minimum
    (`cat /etc/login.defs | grep '^UID_MIN' | sed 's/^UID_MIN[^0-9]*\\([0-9]\\+\\).*$/\\1/'`).to_i # RORSCAN_ITL
  end

  def self.pure_getent
    `getent passwd` # RORSCAN_ITL
  end

  def self.pure_wbinfo
    `which wbinfo >/dev/null && wbinfo -u --domain .` # RORSCAN_ITL
  end
end
