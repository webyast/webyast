
# import global .rake files for plugins
if File.exist? "#{File.dirname(__FILE__)}/../../../webservice/lib/tasks/webservice/"
    # use delopemnt files if we are in git repository
    Dir["#{File.dirname(__FILE__)}/../../../webservice/lib/tasks/webservice/*.rake"].each { |ext| load ext }
else
    # use the files from yast2-webservice package
    Dir["/srv/www/yastws/lib/tasks/webservice/*.rake"].each { |ext| load ext }
end

