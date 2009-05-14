require 'rake'
require 'rubygems'

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

env = %(PKG_BUILD="#{ENV['PKG_BUILD']}") if ENV['PKG_BUILD']
 
PROJECTS = ['webservice', *Dir.glob('plugins/*')]
desc 'Run all tests by default'
task :default => :test
 
%w(test rdoc pgem package release).each do |task_name|
  desc "Run #{task_name} task for all projects"
  task task_name do
    PROJECTS.each do |project|
      system %(cd #{project} && #{env} #{$0} #{task_name})
    end
  end
end

task :system_check do
  Dir.glob("**/*.policy").each do |policy|
    dest_policy = File.join('/usr/share/PolicyKit/policy', File.basename(policy))
    if not File.exists?(dest_policy)
      raise "* Policy '#{policy}' is not installed into '#{dest_policy}'. Run rake install:policies"
      exit(1)
    end
  end
  # now run webservice checks
  system %(cd webservice && #{env} #{$0} system_check)
end


desc "Check syntax of all Ruby files."
task :check_syntax do
  `find . -name "*.rb" |xargs -n1 ruby -c |grep -v "Syntax OK"`
  puts "* Done"
end
