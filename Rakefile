require 'rake'

namespace :install do
  desc "install policies"
  task :policies do |t|
    Dir.glob("**/*.policy").each do |policy|
      sudo "cp #{policy} /usr/share/PolicyKit/policy"
    end
  end
end

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

