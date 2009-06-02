require 'rake'

desc 'Build distribution package'
# just call the checks and then build the package
task :package => [:syntax_check, :git_check, :"package-local"]

