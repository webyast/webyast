require 'fileutils'
require 'yaml'

tracing = (Rake.application.options.trace)?"--trace":""
verbose = (Rake.application.options.verbose)?"--verbose":""

require 'rake'

def sudo(cmd)
  puts "#{cmd}"
  %x[sudo -p "Password: " #{cmd}]
end

#
# recognized variables
#
vars = ['PKG_BUILD', 'RCOV_PARAMS', 'RAILS_ENV', 'RAILS_PARENT']
ENV['RAILS_PARENT'] = File.join(Dir.pwd, 'webyast')

env = ENV.map { |key,val| (ENV[key] && vars.include?( key )) ? %(#{key}="#{ENV[key]}") : nil }.compact.join(' ')

#
# Pick up the plugins as PROJECTS
#

plugins = Dir.glob('plugins/*')#.reject{|x| ['users'].include?(File.basename(x))}
PROJECTS = ['webyast', *plugins]

desc 'Run all tests by default'
task :default => :test

#
# list of common tasks, being run for every plugin
#

%w(notes test gettext:pack rdoc pgem package release install_policies check_syntax package-local buildrpm buildrpm-local test:test:rcov restdoc deploy_local license:report system_check_policies grant_policies).each do |task_name|
  desc "Run #{task_name} task for all projects"

  task task_name do
    PROJECTS.each do |project|
      Dir.chdir(project) do
        if File.exist? "Rakefile"
          system %(#{env} #{$0} #{tracing} #{task_name})
          raise "Error on execute '#{$0} #{tracing} #{verbose} #{task_name}' inside #{project}/" if $?.exitstatus != 0
        end
      end
    end
  end

end


desc "Check if all needed packages are installed correctly for WebYaST"
task :system_check_packages,  [:install] do |t, args|
  args.with_defaults(:install => "")  
  task_name = "system_check_packages"
  PROJECTS.each do |project|
    Dir.chdir project do
      if File.exist? "Rakefile" #avoid endless loop if directory doesn't contain Rakefile
        system %(#{env} #{$0} #{task_name}[#{args.install}] )
        raise "Error on execute task #{task_name} on #{project}" if $?.exitstatus != 0
      end
    end
  end
end

desc "Fetch po files from lcn. Parameter: source directory of lcn e.g. ...lcn/trunk/"
task :fetch_po, [:lcn_dir] do |t, args|
  args.with_defaults(:lcn_dir => File.join(File.dirname(__FILE__),"../../", "lcn", "trunk"))  
  #remove translation statistik
  File.delete(File.join("pot", "translation_status.yaml")) if File.exist?("pot/translation_status.yaml")
  result = Hash.new()
  task_name = "fetch_po"

  PROJECTS.each do |project|
      Dir.chdir project do
        if File.exist? "Rakefile" #avoid endless loop if directory doesn't contain Rakefile
          system %(#{env} #{$0} #{task_name}[#{args.lcn_dir}] )
          raise "Error on execute task #{task_name} on #{project}" if $?.exitstatus != 0
        end
      end

    #collecting translation information
    Dir.glob("#{project}/**/*.po").each {|po_file|
      output = `LANG=C msgfmt -o /dev/null -c -v --statistics #{po_file} 2>&1`
      language = File.basename(File.dirname(po_file))
      output.split(",").each {|column|
        value = column.split(" ")
        if value.size > 2 
          if result.has_key? language 
            if result[language].has_key? value[1]
              result[language][value[1]] += value[0].to_i
            else
              result[language][value[1]] = value[0].to_i
            end
          else
            result[language] = Hash.new
            result[language][value[1]] = value[0].to_i
          end
         end
      }
    }
  end
  
  #saving result to pot/translation_status.yaml
  destdir = File.join(File.dirname(__FILE__), "pot")
  Dir.mkdir destdir unless File.directory?(destdir)
  f = File.open(File.join(destdir, "translation_status.yaml"), "w")
  f.write(result.to_yaml)
  f.close

  #remove translations which have not at least 80 percent translated text
  limit = Float(80)
  result.each {|key,value|
    translated = un_translated = Float(0)
    translated = value["translated"].to_f if value.has_key? "translated"
    un_translated += value["untranslated"].to_f if value.has_key? "untranslated"
    un_translated += value["fuzzy"].to_f if value.has_key? "fuzzy"
    limit_eval = translated/(un_translated+translated) 
    if limit_eval < limit/100
      puts "Language #{key} should be deleted cause it has only #{(limit_eval*100).to_i} percent translation reached."
      Dir.glob("**/#{key}/").each {|po_dir|
        unless po_dir.include? "lang_helper" #do not delete translations for language selections
#          puts "deleting #{po_dir}"
#          remove_dir(po_dir, true) #force=true
        end
      }
    end      
  }
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
  Dir.chdir('webyast') do
    raise "generating documentation fail" unless system "rake doc:app"
  end
  system "cp -r webyast/doc/app doc/webyast"
  puts "create plugins documentation"
  plugins_names = []
  Dir.chdir('plugins') do
    plugins_names = Dir.glob '*'
  end
  plugins_names.each do |plugin|
    Dir.chdir("plugins/#{plugin}") do
      if File.exist? "Rakefile"
        raise "generating documentation fail" unless system "rake doc:app"
      end
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

desc "Deploy for development - create dirs, install configuration files and custom yast modules. Then install and update PolKit policies for root."
# :install policies uses grantwebyastrights, which is installed in :deploy_local
task :deploy_devel_all => [:deploy_local,:install_policies,:grant_policies]

=begin
require 'metric_fu'
MetricFu::Configuration.run do |config|
        #define which metrics you want to use
        config.metrics  = [:churn, :saikuro, :flog, :reek, :roodi, :rcov] #missing flay and stats both not working
        config.graphs   = [:flog, :reek, :roodi, :rcov]
        config.flay     = { :dirs_to_flay => ['webyast', 'plugins']  } 
        config.flog     = { :dirs_to_flog => ['webyast', 'plugins']  }
        config.reek     = { :dirs_to_reek => ['webyast', 'plugins']  }
        config.roodi    = { :dirs_to_roodi => ['webyast', 'plugins'] }
        config.saikuro  = { :output_directory => 'tmp/metric_fu/output', 
                            :input_directory => ['webyast', 'plugins'],
                            :cyclo => "",
                            :filter_cyclo => "0",
                            :warn_cyclo => "5",
                            :error_cyclo => "7",
                            :formater => "html"} #this needs to be set to "text"
        config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
        config.rcov     = { :test_files => ['webyast/test/**/*_test.rb', 
                                            'plugins/**/test/**/*_test.rb'],
                            :rcov_opts => ["--sort coverage", 
                                           "--no-html", 
                                           "--text-coverage",
                                           "--no-color",
                                           "--profile",
                                           "--rails",
                                           "--exclude /gems/,/Library/,spec"]}
    end
=end

=begin
require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['webyast/app/**/*.rb','webyast/lib/**/*.rb','webyast/test/plugin_basic_tests.rb', 'plugins/*/app/**/*.rb', 'plugins/*/lib/**/*.rb','webyast/doc/README_FOR_APP', 'plugins/**/README_FOR_APP']   # optional
  t.options = ['--private', '--protected'] # optional
end
=end

