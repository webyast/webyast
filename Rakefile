require 'rake'
require 'rubygems'

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

vars = ['PKG_BUILD', 'RCOV_PARAMS']

env = ENV.map { |key,val| ENV[key] ? %(#{key}="#{ENV[key]}") : nil }.reject {|x| x.nil?}.join(' ')
#env = %(PKG_BUILD="#{ENV['PKG_BUILD']}") if ENV['PKG_BUILD']

plugins = Dir.glob('plugins/*')#.reject{|x| ['users'].include?(File.basename(x))}
PROJECTS = ['webservice', *plugins]
desc 'Run all tests by default'
task :default => :test

%w(test rdoc pgem package release install install_policies check_syntax package-local buildrpm buildrpm-local test:test:rcov).each do |task_name|
  desc "Run #{task_name} task for all projects"
  task task_name do
    PROJECTS.each do |project|
      system %(cd #{project} && #{env} #{$0} #{task_name})
      raise "Error on execute task #{task_name} on #{project}" if $?.exitstatus != 0    
    end
  end
end


