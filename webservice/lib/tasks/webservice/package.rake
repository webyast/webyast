require 'rake'

# include standard package target definition
load "#{File.dirname(__FILE__)}/../package.rake"

namespace :webservice do

    desc "Perform verification checks and build package"
    task :package => ["webservice:git_check", "webservice:syntax_check", ":package"] do
    end

end
