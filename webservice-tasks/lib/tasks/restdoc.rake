require 'rake'

desc "Generate REST API documentation using 'restility'"
task :restdoc do

    require 'rubygems'
    if Gem.available? 'restility'

	# input file in root plugin directory
	api_file = 'restdoc/api.txt'
	# output directory
	doc_target = Dir.glob('public/**/restdoc').first

	if File.exists?(api_file) && File.exists?(doc_target)
	    puts "Generating REST API documentation in #{doc_target}..."

	    `rest_doc #{api_file} -I #{api_file.split('/').first} --html -o #{doc_target}`
	end
    else
	puts 'Error: restility gem is not installed!'
	exit 1
    end
end

