#
# config/initializers/resource_registration.rb
#

require "lib/resource_registration"

ResourceRegistration.init
if ENV["RAILS_ENV"] == "test"
  ResourceRegistration.register_all "test", "resource_fixtures/good"
else
  ResourceRegistration.register_all "vendor/plugins", "config/resources"
end
