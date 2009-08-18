# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'basesystem'

class BasesystemTest < Test::Unit::TestCase
  
  def setup
    fh = File.new(Basesystem.STEPS_FILE, "r")
    @test_steps = fh.lines.collect { |l| chomp l}.delete_if{|l| length l == 0}
    fh.close
    @basesystem = Basesystem.find
  end
  
  def teardown
    File.delete(Basesystem.CURRENT_STEP_FILE)
  end
  
  def test_steps
    assert_equal(@test_steps, @basesystem.steps)
  end

  def test_current
    assert_equal(@basesystem.current, @test_steps[0])
  end

  def test_save
    @basesystem.current = @test_steps[0]
    @basesystem.save
    @basesystem = Basesystem.find
    assert_equal(@test_steps[0], @basesystem.current)
    # test for save fail on invalid current step
    @basesystem.current = "ridiculous"
    assert(false, @basesystem.save)
  end

  def test_corrupted_current
    fh = File.new(Basesystem.CURRENT_STEP_FILE)
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
