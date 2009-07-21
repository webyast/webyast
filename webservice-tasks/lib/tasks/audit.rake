
desc "Audits source code"
namespace :audit do
  task :roodi do
    system 'find app/ lib/ -name \*.rb | xargs roodi > log/code-analysis/roodi.log'
    system "echo 'log in webservice/log/roodi.log'"
  end
end
