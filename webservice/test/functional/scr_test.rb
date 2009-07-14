#
# test/functional/scr_test.rb
#
# This tests lib/scr, the Scr proxy for YaST D-Bus
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class ScrTest < ActiveSupport::TestCase

  require "scr"

  test "instanciating the scr singleton" do
    assert Scr.instance
  end

  test "scr read" do
    assert Scr.instance.read ".target.tmpdir"
  end

  test "scr read with argument" do
    Scr.instance.read(".target.string", __FILE__)
  end

  test "scr write" do
    scr = Scr.instance
    
    # try to write to a temporary file
    tmpdir = scr.read( ".target.tmpdir" );
    assert tmpdir
    s = Process.pid.to_s
    f = "#{tmpdir}/#{s}" # a temp file
# Hmm, PolicyKit prevents testing 'write'
#    scr.write(".target.string", f, s)
#    assert scr.read(".target.string", f) == s
    scr.execute(["/bin/rm", f])
    # Uh-oh
    assert scr.read(".target.stat", f).to_s.empty?
  end
  
  test "scr execute" do
    assert Scr.instance.execute(["/bin/date"])
  end
end
