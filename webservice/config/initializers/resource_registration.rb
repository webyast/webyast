#
# config/initializers/resource_registration.rb
#

require "lib/resource_registration"

# go here only during test, development or production
# but not during "rake db:migrate" from command line
#
# FIXME: needs a better test

if ENV["RAILS_ENV"] == "test"
  ResourceRegistration.init
  ResourceRegistration.register_all "test", "resource_fixtures/good"
elsif ENV["RAILS_ENV"] == "development" or ENV["RAILS_ENV"] == "production"
  ResourceRegistration.init
  ResourceRegistration.register_all File.join(RAILS_ROOT, "vendor/plugins"), "config/resources"
end
