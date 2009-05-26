require 'rake'

desc "Check syntax of all Ruby (*.rb) files"
task :syntax_check do
    puts "* Starting syntax check..."

    # check all *.rb files
    Dir.glob("**/*.rb").each do |file|

	`ruby -c #{file}`

	if $?.exitstatus != 0
	    puts "ERROR: Syntax error found"
	    exit 1
	end
    end

    puts "* Done"
end

