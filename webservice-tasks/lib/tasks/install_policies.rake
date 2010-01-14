require 'fileutils'

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

desc "install policies"
task :install_policies do |t|
  puts "Running from #{__FILE__}"
  Dir.glob("**/*.policy").each do |policy|
    FileUtils.cp("#{policy}", "/usr/share/PolicyKit/policy")
  end
  system "/usr/sbin/grantwebyastrights --user root --action grant >/dev/null 2>&1"
  raise "Error on execute '#{$0} #{tracing} #{verbose} #{task_name}'" if $?.exitstatus != 0
end

