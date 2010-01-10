require 'rake'


class WebserviceTasks

    # a flag - load the tasks just once, multiple loading
    # leads to multiple invocation of the same task
    @@tasks_loaded = false

    # load webservice *.rake files, exclude/include list can be specified
    def WebserviceTasks.loadTasks(params = {:include => ["*.rake"], :exclude => []})
	return if @@tasks_loaded

	exclude_list = []
	if params[:exclude].nil?
	    params[:exclude] = []
	end

	# expand exclude files
	params[:exclude].each { |efile| exclude_list += Dir["#{File.dirname(__FILE__)}/#{efile}"]}

	include_list = []
	if params[:include].nil?
	    params[:include] = ["*.rake"]
	end

	# expand include files
	params[:include].each { |ifile| include_list += Dir["#{File.dirname(__FILE__)}/#{ifile}"]}

	# load an include file only if it not in the exclude list
	include_list.each { |ext|
	    if !exclude_list.include?(ext)
		load ext
	    end
	}

	@@tasks_loaded = true
    end

end

# vim: ft=ruby
