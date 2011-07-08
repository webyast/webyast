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

require File.join(File.dirname(__FILE__),"..", "test_helper")

class Testing
  cattr_reader :arg1,:arg2
  def self.action arg1,arg2
    @@arg1,@@arg2 = arg1, arg2
  end
end


class PluginJobTest < ActiveSupport::TestCase

  def setup
  end

  def teardown
    Delayed::Job.delete_all
  end

  test "try running" do
    job = PluginJob.new(:Testing,:action,["test","lest"])
    job.perform
    assert_equal "test", Testing.arg1
    assert_equal "lest", Testing.arg2
  end

  test "try serialize instance and check it" do
    [1,{:t => "l"},Time.now].each do |object|
      assert PluginJob.run_async(0,object,:to_s)
      assert PluginJob.running?(object, :to_s), "#object('#{object}') is not running"
    end
  end

  test "try serialize class and check it" do
    [:Object,:Integer].each do |object|
      assert PluginJob.run_async(0,object,:to_s)
      assert PluginJob.running?(object, :to_s)
    end
  end

  test "try non running job" do
    assert !PluginJob.running?(5,:to_s)
    assert !PluginJob.running?(:Object,:to_s)
  end
end
