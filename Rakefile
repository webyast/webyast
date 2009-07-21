require 'rake'
require 'rubygems'

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

env = %(PKG_BUILD="#{ENV['PKG_BUILD']}") if ENV['PKG_BUILD']
 
plugins = Dir.glob('plugins/*').reject{|x| ['users'].include?(File.basename(x))}
PROJECTS = ['webservice', *plugins]
desc 'Run all tests by default'
task :default => :test
 
%w(test rdoc pgem package release install install_policies check_syntax package-local).each do |task_name|
  desc "Run #{task_name} task for all projects"
  task task_name do
    PROJECTS.each do |project|
      system %(cd #{project} && #{env} #{$0} #{task_name})
    end
  end
end


