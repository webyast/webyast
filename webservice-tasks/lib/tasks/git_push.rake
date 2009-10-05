require 'rake'

desc "Push to git repository. Don't use directly, use push instead!"
task :git_push do
    out = `git push`
    puts '* GIT push OK'
end

