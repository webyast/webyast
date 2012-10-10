#--
# Webyast framework
#
# Copyright (C) 2012 Novell, Inc.
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

require 'singleton'

# ruby-dbus bindings are NOT thread safe
# no DBus call can be run in parallel (causes a hard crash)
#
# DbusLock ensures that a DBus request runs in a critical section
# guarded by a Mutex

class DbusLock

  include Singleton

  def initialize
    @lock = Mutex.new
  end

  def locked?
    @lock.locked?
  end

  def synchronize
    @lock.synchronize do
      yield
    end
  end

  # just a shortcut for the instance method
  def self.locked?
    DbusLock.instance.locked?
  end

  # any DBus call has to be wrapped in DbusLock.synchronize call
  # which ensures that only one process is using DBus at a time
  def self.synchronize
    Rails.logger.info "Waiting for DBus lock... (#{caller(2).first})"

    DbusLock.instance.synchronize do
        Rails.logger.info "DBus lock obtained (#{caller(3).first})"
        yield
    end

    Rails.logger.info "DBus lock released"
  end

end
