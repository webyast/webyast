require "lib/resource"
  
# routing is generated from the 'resources' database table
# see config/initializers/resource_registration.rb for populating the database
  
ResourceRegistration.route_all

$stderr.puts ActionController::Routing::Routes.routes if ENV["RAILS_ENV"] == "development"
