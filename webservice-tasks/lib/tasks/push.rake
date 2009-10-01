require 'rake'

desc 'Push commits to git and checks if it doesn\'t break anything'
# just call the checks and then build the package
task :push => [:check_syntax, :test, :restdoc, :"package-local", :build_test, :git_push]

