require 'fileutils'

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

desc "install policies"
task :install_policies do |t|
  puts "Running from #{__FILE__}"
  Dir.glob("**/*.policy").each do |policy|
    FileUtils.cp "#{policy}" "/usr/share/PolicyKit/policy"
    `#{cmd}`
  end
end

