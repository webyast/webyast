require 'rake/testtask'

desc 'Test the permissions plugin.'
Rake::TestTask.new(:test) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.test_files = FileList['test/**/*_test.rb'].exclude("test/ui/**/*")
    t.verbose = true
end
