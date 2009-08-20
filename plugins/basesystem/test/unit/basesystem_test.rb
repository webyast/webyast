require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class BasesystemTest < ActiveSupport::TestCase

  def setup
    fh = File.new(Basesystem.steps_file, "r")
    @test_steps = fh.lines.collect { |l| l.chomp}.delete_if{|l| l.length == 0}
    fh.close
    @basesystem = Basesystem.find
  end
  
  def teardown
    if File.exists?(Basesystem.current_step_file)
      File.delete(Basesystem.current_step_file)
    end
  end
  
  def test_steps
    @basesystem = Basesystem.find
    assert_equal(@test_steps, @basesystem.steps)
  end

  def test_current
    assert_equal(@basesystem.current, @test_steps[0])
  end

  def test_save
    @basesystem.current = Basesystem.end_string
    @basesystem.save
    @basesystem = Basesystem.find
    assert_equal(Basesystem.end_string, @basesystem.current)
    # test for save fail on invalid current step
    @basesystem.current = "ridiculous"
    assert !@basesystem.save
  end

  def test_corrupted_current
    fh = File.new(Basesystem.current_step_file, "w")
    fh << "ridiculous"
    fh.close
    @basesystem = Basesystem.find
    assert_equal(@test_steps[0], @basesystem.current)
  end

  def test_to_xml
    assert_not_nil(@basesystem.to_xml)
  end

  def test_to_json
    assert_not_nil(@basesystem.to_json)
  end

end
