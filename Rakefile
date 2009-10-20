tracing = (Rake.application.options.trace)?"--trace":""
verbose = (Rake.application.options.verbose)?"--verbose":""

require 'rake'
require 'rubygems'
#require 'metric_fu'

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

# recognized variables
vars = ['PKG_BUILD', 'RCOV_PARAMS', 'RAILS_ENV', 'RAILS_PARENT']
ENV['RAILS_PARENT'] = File.join(Dir.pwd, 'webservice')

env = ENV.map { |key,val| (ENV[key] && vars.include?( key )) ? %(#{key}="#{ENV[key]}") : nil }.reject {|x| x.nil?}.join(' ')

plugins = Dir.glob('plugins/*')#.reject{|x| ['users'].include?(File.basename(x))}
PROJECTS = ['webservice', *plugins]
desc 'Run all tests by default'
task :default => :test

%w(test rdoc pgem package release install install_policies check_syntax package-local buildrpm buildrpm-local test:test:rcov).each do |task_name|
  desc "Run #{task_name} task for all projects"

  task task_name do
    PROJECTS.each do |project|
      Dir.chdir(project) do
        system %(#{env} #{$0} #{tracing} #{task_name})
        raise "Error on execute '#{$0} #{tracing} #{verbose} #{task_name}' inside #{project}/" if $?.exitstatus != 0
      end
    end
  end

end

desc "Run doc to generate whole documentation"
task :doc do
  #clean old documentation
  puts "cleaning old doc"
  system "rm -rf doc"
  
  Dir.mkdir 'doc'
  copy 'index.html.template', "doc/index.html"
  #handle rest service separate from plugins
  puts "create framework documentation"
  Dir.chdir('webservice') do
    system "rake doc:app"
  end
    system "cp -r webservice/doc/app doc/webservice"
  puts "create plugins documentation"
  plugins_names = []
  Dir.chdir('plugins') do
    plugins_names = Dir.glob '*'
  end
  plugins_names.each do |plugin|
    Dir.chdir("plugins/#{plugin}") do
      system "rake doc:app"
    end
    system "cp -r plugins/#{plugin}/doc/app doc/#{plugin}"
  end
  puts "generate links for plugins"
  code = ""
  plugins_names.sort.each do |plugin|
    code = "#{code}<a href=\"./#{plugin}/index.html\"><b>#{plugin}</b></a><br>"
  end
  system "sed -i 's:%%PLUGINS%%:#{code}:' doc/index.html"
  puts "documentation successfully generated"
end

