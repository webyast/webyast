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

    @bm.update_progress(:dummy) do |s|
      s.progress = 10
    end
    assert_equal nil, @bm.get_progress(:dummy)


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
