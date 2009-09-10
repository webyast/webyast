require 'rake'

desc 'Build distribution package'
# just call the checks and then build the package
task :package => [:check_syntax, :git_check, :restdoc, :"package-local"]

