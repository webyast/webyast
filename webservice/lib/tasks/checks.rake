###
# Helpers
#

def escape why, fix = nil
  $stderr.puts "*** Error: #{why}"
  $stderr.puts "Please #{fix}" if fix
  exit
end

def test what
  escape "(internal error) wrong use of 'test'" unless block_given?
  puts "Testing if #{what}"
  yield
end

def test_module name, package
  puts "Testing if #{package} is installed"
  begin
    require name
  rescue Exception => e
    escape "#{package} not installed", "install #{package}"
  end
end

def test_version package, version
  v = `rpm -q #{package}`
  escape v, "install #{package} >= #{version}" if v =~ /is not installed/
  nvr = v.split "-"
  rel = nvr.pop
  ver = nvr.pop
  escape "#{package} not up-to-date", "upgrade to #{package}-#{version}"  if ver < version
end

###
# Tests
#

desc "install policies"
task :install_policies do |t|
  Dir.glob(File.join(Dir.pwd, '..', "**/*.policy")).each do |policy|
    puts "copying #{policy} -> /usr/share/PolicyKit/policy"
    `cp #{policy} /usr/share/PolicyKit/policy`
  end
end

task :system_check do
  # check that policies are all installed
  Dir.glob(File.join(File.dirname(__FILE__), '..', "**/*.policy")).each do |policy|
    dest_policy = File.join('/usr/share/PolicyKit/policy', File.basename(policy))
    if not File.exists?(dest_policy)
      raise "* Policy '#{policy}' is not installed into '#{dest_policy}'. Run rake install_policies"
      exit(1)
    end
  end

  user = ENV['USER']
  policykit_conf = <<EOF
<match user="#{user}">
    <match action="org.opensuse.yast.scr.*">
      <return result="yes"/>
    </match>
  </match>
  <match user="#{user}">
    <match action="org.freedesktop.packagekit.system-update">
      <return result="yes"/>
    </match>
  </match>
  <match user="#{user}">
    <match action="org.freedesktop.policykit.read">
      <return result="yes"/>
    </match>
  </match>
EOF

  # will the webservice be able to run?
  webservice_permissions_ok = false

  # get all granted policies
  granted = `polkit-auth --user #{user}`.split

  # check that the user running the web service has permissions to yast
  # scr and others. This can be achieved in 2 ways:
  # manually polkit-auth, or as pattern matching in /etc/PolicyKit/PolicyKit.conf

  scr_actions = `polkit-action`.split.reject { |item| not item.include?('org.opensuse.yast.scr.') }
  webservice_actions = [ 'org.freedesktop.packagekit.system-update', 'org.freedesktop.policykit.read', *scr_actions]

  webservice_actions.each do | action|
    if not granted.include?(action)
      escape "policy #{action} is not granted and it is needed to run the webservice as #{user}.", "Run 'polkit-auth --user #{user} --grant #{action}'\nTo grant it, or use utility script policyKit-rights.rb to grant them all.\nSee http://en.opensuse.org/YaST/Web/Development\n\nAlternatively, you can add the following to /etc/PolicyKit/PolicyKit.conf config tag section:\n#{policykit_conf}\n"
    end
  end

  # now check that all permission in each policy is granted
  Dir.glob(File.join(Dir.pwd, '..', "**/*.policy")).each do |policy|
    doc = REXML::Document.new(File.open(policy))
    doc.elements.each("/policyconfig/action") do |action|
      id = action.attributes['id']
      if not granted.include?(id)
        puts "\nWARNING!!\n\npolicy #{id} is not granted for current user.\n\nIf you plan to login to YaST as '#{user}', run 'polkit-auth --user #{user} --grant #{id}'\nTo grant it, or use utility script policyKit-rights.rb to grant them all.\nSee http://en.opensuse.org/YaST/Web/Development\nYou can also grant them to the root user and login as root to the YaST web client.\n\n"
      end
    end
  end

  #
  # rpam        
  # 
  test_module "rpam", "ruby-rpam"
  #
  # ruby-polkit
  #
  test_module "polkit", "ruby-polkit"
  #
  # /etc/yast_user_roles
  #
  test "User roles configured" do
    unless File.exists? "/etc/yast_user_roles"
      escape "/etc/yast_user_roles does not exist", "create /etc/yast_user_roles"
    end
  end

  #
  # ruby-dbus
  #
  test_module "dbus", "ruby-dbus"

  #
  # yast-dbus, scr
  #

  test "YaST D-Bus service available" do
    begin
      require "dbus"
      bus = DBus::SystemBus.instance
    rescue Exception => e
    end
    escape "System error, cannot access D-Bus SystemBus" unless bus
    begin
      proxy = bus.introspect( "org.opensuse.yast.SCR", "/SCR" )
    rescue Exception => e
    end
  
    package = "yast2-core"
    version = "2.18.10"
    unless proxy
      $stderr.puts "YaST D-Bus service not available"
      test_version package, version
      escape "#{package} not correctly installed", "reinstall #{package}-#{version}"
    end
    begin
      scr = proxy["org.opensuse.yast.SCR.Methods"]
    rescue Exception => e
    end
    escape "YaST D-Bus does not provide the right data", "reinstall #{package}-#{version}" unless scr
  end
  puts "All fine, rest-service is ready to run"
end