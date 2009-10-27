require 'rake'

desc 'Submit package to Yast:Web and checks before if it doesn\'t break anything'
# just call the checks and then build the package
task :submit => [:check_syntax, :test, :restdoc, :"package", :build_test, :osc_submit]

