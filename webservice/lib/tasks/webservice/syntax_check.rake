require 'rake'

namespace :webservice do

    desc "Check syntax of all Ruby (*.rb) files"
    task :syntax_check do
      `find . -name "*.rb" |xargs -n1 ruby -c |grep -v "Syntax OK"`
      puts "* Done"
    end

end

