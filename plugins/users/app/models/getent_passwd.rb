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
require 'base'
# Group model, YastModel based
class GetentPasswd < BaseModel::Base
  attr_accessor :login
  attr_accessor :full_name

  def self.find
    result = []
    minimum = system_minimum # RORSCAN_ITL
    minimum = 1000 if minimum == 0 #fallback
    getent_passwd.each do |user_line|
      elements = user_line.split ":"
      #TODO: Find a better solution for user which UID < 1000
      #possible solution could be config.yml where vendor can set UID range
      #elements[1] != 'x' workaround, since some user has UID < 1000
      if elements[2].to_i >= minimum && elements[0] != "nobody" || (elements[1] != 'x' && elements[2].to_i <= minimum ) #bnc#632326
        name = elements[4].split(/\s*,\s*/)
        result << GetentPasswd.new(:login => elements[0], :full_name => name[0])
      end
    end
    wbinfo.each do |login|
      login.chomp!
      result << GetentPasswd.new(:login => login, :full_name => login)
    end
    result
  end

private
  def self.system_minimum
    (`cat /etc/login.defs | grep '^UID_MIN' | sed 's/^UID_MIN[^0-9]*\\([0-9]\\+\\).*$/\\1/'`).to_i # RORSCAN_ITL
  end

  def self.getent_passwd
    entries = `getent passwd`.split "\n"
    Rails.logger.warning "Command 'getent passwd' returned no entries." if entries.empty?
    entries
  rescue Errno::ENOENT => e
    Rails.logger.error "Execution of command 'getent passwd' failed: #{e.message}"
    entries = []
  end

  def self.wbinfo
    wbinfo = `wbinfo -u --domain . 2> /dev/null`.split "\n"
    Rails.logger.info "Command 'wbinfo -u --domain .' returned no entries." if wbinfo.empty?
    wbinfo
  rescue Errno::ENOENT => e
    Rails.logger.error "Execution of command 'wbinfo -u --domain .' failed: #{e.message}"
    wbinfo = []
  end

end
