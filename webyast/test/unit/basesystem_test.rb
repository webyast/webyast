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

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require "yast/config_file"
require 'tempfile'

class BasesystemTest < ActiveSupport::TestCase

STEPS = <<EOF
steps:
  - controller: time
  - controller: language
    action: show
EOF

EMPTY_STEPS = <<EOF
steps:
#  - controller: time
#  - controller: language
#    action: show
EOF

  TEST_STEPS = ["time","language"]
  def setup
    #set const to run test in this directory
    tmpfile = Tempfile.new('finish').path
    File.delete tmpfile #remove it by default

    Basesystem.undef_constant # fix: "warning: already initialized constant FINISH_FILE"
    Basesystem.const_set "FINISH_FILE", tmpfile
    YaST::ConfigFile.stubs(:read_file).returns(STEPS)
    YaST::ConfigFile.any_instance.stubs(:path).returns(__FILE__)
    @basesystem = Basesystem.find({})
  end

  def teardown
    finish = Basesystem.const_get "FINISH_FILE"
    if File.exist?(finish)
      File.delete(finish)
    end
  end

  def test_steps
    assert_equal(TEST_STEPS, @basesystem.steps)
  end

  def test_finish
    assert !@basesystem.finish
  end

  def test_save
    @basesystem.finish = true
    @basesystem.save
    nbase = Basesystem.find({})
    assert nbase.finish
  end

  def test_save_step
    @basesystem.done = "time"
    @basesystem.save
    nbase = Basesystem.find({})
    assert !nbase.finish
    assert_equal "time", nbase.done
  end

  def test_to_xml
    assert_not_nil @basesystem.to_xml
  end

  #  ??? undefined method `session' for #<Basesystem:0x7f2bc5ccd268>
  def test_to_json
    assert_not_nil @basesystem.as_json
  end


  # ???  test_mass_loading(BasesystemTest) [test/unit/basesystem_test.rb:94]: <false> is not true.
  def test_mass_loading
    bs = Basesystem.new :finish => true, :steps => [:lest], :done => :lest
    assert bs.finish #only finish is set
    assert !bs.steps.nil?
    assert !bs.done.nil?
  end

  # Test what happens if the config file is not found
  # bnc#592584
  def test_broken_config
    YaST::ConfigFile.any_instance.stubs(:path).returns("")
    assert_nothing_raised do Basesystem.find({}) end
  end

  def test_default_find
    YaST::ConfigFile.stubs(:read_file).returns(EMPTY_STEPS)
    basesystem = Basesystem.find({})
    assert basesystem.finish
  end
end
