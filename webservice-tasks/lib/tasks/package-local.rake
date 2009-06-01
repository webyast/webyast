require 'rake'
require 'rake/packagetask'

Rake::PackageTask.new('www', :noversion) do |p|
  p.need_tar_bz2 = true
  p.package_dir = 'package'
  p.package_files.include('**/*')
  p.package_files.exclude('package')
end


# add new rename method to Rake::Task class
class Rake::Task
    def rename(new_name)
	if !rename.nil? && !rename.blank?
	    @name = new_name
	end
    end
end

# rename :package task to :package-local task
Rake::Task[:package].rename(:"package-local")

