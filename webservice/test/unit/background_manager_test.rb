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

require File.dirname(__FILE__) + '/../test_helper'

class BackgroundManagerTest < ActiveSupport::TestCase
  def setup
     @bm = BackgroundManager.instance
  end

  def test_instance_not_nil
    assert_not_equal nil, @bm
  end

  def test_background_manager

    # no background progress created yet
    assert !@bm.process_running?(:dummy)
    assert !@bm.process_finished?(:dummy)
    assert_equal nil, @bm.get_progress(:dummy)
    assert_equal nil, @bm.get_value(:dummy)

    @bm.update_progress(:dummy)
    assert_equal nil, @bm.get_progress(:dummy)

    changed = false
    @bm.update_progress(:dummy) do |s|
      # this block must NOT be executed
      s.progress = 10
      changed = true
    end
    assert_equal nil, @bm.get_progress(:dummy)
    assert !changed


    # register a process
    @bm.add_process(:test)

    assert @bm.process_running?(:test)
    assert !@bm.process_finished?(:test)
    assert_not_equal nil, @bm.get_progress(:test)
    assert_equal 0, @bm.get_progress(:test).progress
    assert_equal nil, @bm.get_value(:test)


    # update progress
    pr = 42
    sp = 10
    st = 'testing'
    @bm.update_progress(:test) do |p|
      p.status = st
      p.progress = pr
      p.subprogress = sp
    end

    assert @bm.process_running?(:test)
    assert !@bm.process_finished?(:test)
    assert_not_equal nil, @bm.get_progress(:test)
    assert_equal st, @bm.get_progress(:test).status
    assert_equal pr, @bm.get_progress(:test).progress
    assert_equal sp, @bm.get_progress(:test).subprogress
    assert_equal nil, @bm.get_value(:test)


    # finish the process, set a final value
    final_value = 'final_value'
    @bm.finish_process(:test, final_value)
    assert !@bm.process_running?(:test)
    assert @bm.process_finished?(:test)
    assert_equal nil, @bm.get_progress(:test)
    assert_equal final_value, @bm.get_value(:test)


    # the result is removed after reading
    assert_equal nil, @bm.get_value(:test)
    assert !@bm.process_running?(:test)
    assert !@bm.process_finished?(:test)

    # check the config call
    assert_equal Rails.configuration.cache_classes, @bm.background_enabled?
  end


end
