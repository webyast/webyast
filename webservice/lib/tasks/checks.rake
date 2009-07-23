###
# Helpers
#

def escape why, fix = nil
  $stderr.puts "*** ERROR: #{why}"
  $stderr.puts "Please #{fix}" if fix
end

def warn why, fix = nil
  $stderr.puts "*** WARNING: #{why}"
  $stderr.puts "Please #{fix}" if fix
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
  old_lang = ENV['LANG']
  ENV['LANG'] = 'C'
  v = `rpm -q #{package}`
  ENV['LANG'] = old_lang
  escape v, "install #{package} >= #{version}" if v =~ /is not installed/
  nvr = v.split "-"
  rel = nvr.pop
  ver = nvr.pop
  escape "#{package} not up-to-date", "upgrade to #{package}-#{version}"  if ver < version
end

###
# Tests
#

desc "Check that your build environment is set up correctly for WebYaST"
task :system_check do

  errors = false

  #
  # check needed needed packages
  #
  version = "0.0.1" # do not take care
  test_version "libsqlite3-0", version
  test_version "PolicyKit", version
  test_version "PackageKit", version

  #
  # check needed modules
  # 
  test_module "rake", "rubygem-rake"
  test_module "sqlite3", "rubygem-sqlite3"
  test_module "rake", "rubygem-rake"
  test_module "rpam", "ruby-rpam"
  test_module "polkit", "ruby-polkit"
  test_module "dbus", "ruby-dbus"

  # check that policies are all installed
  not_needed = ['org.opensuse.yast.scr.policy']
  policy_files = File.join(File.dirname(__FILE__), '../../..', "**/*.policy")
  Dir.glob(policy_files).map { |x| File.basename(x) }.reject { |x| not_needed.include?(x) }.each do |policy|
    dest_policy = File.join('/usr/share/PolicyKit/policy', policy)
    if not File.exists?(dest_policy)
      escape "Policy '#{policy}' is not installed into '#{dest_policy}'", "Run \"rake install\" in the concerning module/plugin"
      errors = true
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
  granted = `polkit-auth --user #{user} --explicit`.split

  # check that the user running the web service has permissions to yast
  # scr and others. This can be achieved in 2 ways:
  # manually polkit-auth, or as pattern matching in /etc/PolicyKit/PolicyKit.conf

  scr_actions = `polkit-action`.split.reject { |item| not item.include?('org.opensuse.yast.scr.') }
  webservice_actions = [ 'org.freedesktop.packagekit.system-update', 'org.freedesktop.packagekit.install',  'org.freedesktop.policykit.read', *scr_actions]

  hint_message = "Use utility script policyKit-rights.rb to grant them all. See http://en.opensuse.org/YaST/Web/Development\nAlternatively, you can add the following to /etc/PolicyKit/PolicyKit.conf config tag section:\n#{policykit_conf}\n"

  webservice_actions.each do | action|
    if not granted.include?(action)
      escape "policy #{action} is not granted and it is needed to run the webservice as #{user}.", "Run 'polkit-auth --user #{user} --grant #{action}' to grant the permission.\n"+hint_message
      hint_message = ""
      errors = true
    end
  end

  # now check that all permission in each policy is granted
  hint_message = "\nUse utility script policyKit-rights.rb to grant them all.\nSee http://en.opensuse.org/YaST/Web/Development\nYou can also grant them to the root user and login as root to the YaST web client.\n\n"
  Dir.glob(File.join(File.dirname(__FILE__), '../../..', "**/*.policy")).each do |policy|
    doc = REXML::Document.new(File.open(policy))
    doc.elements.each("/policyconfig/action") do |action|
      id = action.attributes['id']
      if not granted.include?(id)
        warn "policy #{id} is not granted for current user.", " fix it if you plan to login to YaST as '#{user}', run 'polkit-auth --user #{user} --grant #{id}' to grant it." + hint_message
        hint_message = ""
        errors = true
      end
    end
  end

  #
  # /etc/yast_user_roles
  #
  test "User roles configured" do
    unless File.exists? "/etc/yast_user_roles"
      escape "/etc/yast_user_roles does not exist", "Create /etc/yast_user_roles using template in webservice/package/yast_user_roles"
      errors = true
    end
  end

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
      errors = true
    end
    begin
      scr = proxy["org.opensuse.yast.SCR.Methods"]
    rescue Exception => e
    end
    escape "YaST D-Bus does not provide the right data", "reinstall #{package}-#{version}" unless scr
    errors = true
  end

  #
  # plugin test. Each plugin will be tested for a "GET index" call. This call has to return "success"
  #

  test "all available plugins are working" do
     Dir.glob(File.join(File.dirname(__FILE__), '../../../plugins', "**/*_controller.rb")).each do |controller|
       modulename = File.basename(controller, ".rb").split("_").collect { |i| i.capitalize }.join
       modulepath = File.dirname(controller).split("/")
       # add Namespaces to the modulename. 
       # They are defined as subdirectories in the controller directory
       while modulepath
         namespace = modulepath.pop
         if namespace == "controllers"
           modulepath = nil
         else
           modulename = namespace.capitalize + "::" + modulename
         end
       end
       ok = system %(cd #{File.dirname(__FILE__)}; export RAILS_PARENT=../../; ruby plugin_test/functional/plugin_index_test.rb --plugin #{modulename} > /dev/null)
       if !ok
          # puts "Trying \"GET show\" cause some plugins do not support \"GET index\"..."
          ok = system %(cd #{File.dirname(__FILE__)}; export RAILS_PARENT=../../; ruby plugin_test/functional/plugin_show_test.rb --plugin #{modulename} > /dev/null)
       end
       escape "plugin #{modulename} does not work correctly", "try 'export RAILS_PARENT=.; ruby plugin_test/functional/plugin_index_test.rb --plugin #{modulename}' and check the result" unless ok
       errors = true
     end
  end
  
  if !errors 
    puts ""
    puts "**************************************"
    puts "All fine, rest-service is ready to run"
    puts "**************************************"
  else
    puts ""
    puts "*******************************************************"
    puts "Please, fix the above errors before running the service"
    puts "*******************************************************"
  end
end
