#
# test/functional/scr_test.rb
#
# This tests lib/scr, the Scr proxy for YaST D-Bus
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class ScrTest < ActiveSupport::TestCase

  require "scr"
  
  SERVICE = "org.opensuse.yast.SCR"
  PATH = "/SCR"
  INTERFACE = "#{SERVICE}.Methods"
  
  def setup
    # stub D-Bus/SCR, see lib/scr.rb
    @scr_proxy = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, PATH)
    @scr_iface = DBus::ProxyObjectInterface.new(@scr_proxy, SERVICE)
    # must stub class method here, 'Singleton' seems to prevent instance stubbing ?!
    @scr_iface.class.any_instance.stubs(:Write).returns(true)
    @scr_iface.class.any_instance.stubs(:Read).returns([["","",""]])
    @scr_iface.class.any_instance.stubs(:Execute).returns([[nil,nil,{"exit"=>[0,0,0],"stdout"=>["","",""], "stderr"=>["","",""]}]])
    
    @scr_proxy[INTERFACE] = @scr_iface
    DBus::SystemBus.any_instance.stubs(:introspect).with(SERVICE,PATH).returns(@scr_proxy)
  end
  
  test "instanciating the scr singleton" do
    assert Scr.instance
  end

  test "scr read" do
    assert Scr.instance.read ".target.tmpdir"
  end

  test "scr read with argument" do
    Scr.instance.read(".target.string", __FILE__)
  end

  test "scr execute with good args" do
    res = Scr.instance.execute ["ABCabc123", "_", "-", "/", "=", ":", ".", "\"", "<", ">", " ", "_-/=:.,\"<> ", "" ]
    assert res[:exit] != 2
  end
  
  test "scr execute with bad args" do
    res = Scr.instance.execute ["|"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["/bin/date | ls /"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["ls $foo"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["%"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["@"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["foo & bar"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["cd (foo)"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["ls *?"]
    assert_equal 2, res[:exit]
    res = Scr.instance.execute ["'foo'"]
    assert_equal 2, res[:exit]
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
