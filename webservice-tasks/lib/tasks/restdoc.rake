require 'rake'

# This task generates REST API documentation from restdoc/api.txt file
# if it has been found. The generated HTML documentation is stored
# to public/*/restdoc directory. (Plugins set the target by creating
# restdoc directory somewhere in public/ subdirectory.)

desc "Generate REST API documentation using 'restility'"
task :restdoc do

    require 'rubygems'
    if Gem.available? 'restility'

	# input file in root plugin directory
	api_file = 'restdoc/api.txt'
	# output directory
	doc_target = Dir.glob('public/**/restdoc').first

	if File.exists?(api_file) && !doc_target.nil? && File.directory?(doc_target)
	    puts "Generating REST API documentation in #{doc_target}..."

	    `rest_doc #{api_file} -I #{api_file.split('/').first} --html -o #{doc_target}`
        else
            puts "Skipping restdoc: restdoc/api.txt or public/**/restdoc/ not found."
	end
    else
	puts 'Error: restility gem is not installed!'
	exit 1
    end
end

