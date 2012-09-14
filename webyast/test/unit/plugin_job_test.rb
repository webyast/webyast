#--
# Webyast framework
#
# Tests for lib/plugin_job.rb
#
# Copyright (C) 2012 Novell, Inc.
#
# This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

require File.join(File.dirname(__FILE__),"..", "test_helper")

class PluginJobTest < ActiveSupport::TestCase

  ##
  # Tests for PluginJob#try_updating_db
  ##

  test "DB access: sqlite still fails" do
    exception = SQLite3::SQLException.new("cannot start a transaction within a transaction: begin transaction")

    assert_raise SQLite3::SQLException do
      PluginJob.try_updating_db do
        raise exception
      end
    end
  end

  # missing block is OK, results in nil
  test "DB access: no block passed" do
    ret = nil

    assert_nothing_raised do
      ret = PluginJob.try_updating_db
    end

    assert_equal nil, ret
  end

  test "DB access: sqlite fails but then passes" do
    exception = SQLite3::SQLException.new("cannot start a transaction within a transaction: begin transaction")
    counter = 0
    ret = nil

    assert_nothing_raised do
      ret = PluginJob.try_updating_db do
        counter += 1
        raise exception if counter < 10
        "result"
      end
    end

    # check the returned value
    assert_equal "result", ret
  end

  test "DB access: non-sqlite exception is not retried" do
    exception = StandardError.new("generic error")
    counter = 0

    assert_raise StandardError do
      PluginJob.try_updating_db do
        counter += 1
        raise exception
      end
    end

    # just one attempt, no retry
    assert_equal 1, counter
  end


end
