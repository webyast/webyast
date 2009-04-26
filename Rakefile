require 'rake'

namespace :install do
  desc "install policies"
  task :policies do |t|
    Dir.glob("**/*.policy").each do |policy|
      cp policy, '/usr/share/PolicyKit/policy'
    end
  end
end
