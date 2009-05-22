require 'rake'

namespace :webservice do

    desc "Check syntax of all Ruby (*.rb) files"
    task :syntax_check do
	puts "* Starting syntax check..."
	out = `find . -name "*.rb" |xargs -n1 ruby -c |grep -v "Syntax OK"`
	if out.empty?
	    puts "* Done"
	else
	    puts "Syntax error found"
	    exit 1
	end
    end

end

