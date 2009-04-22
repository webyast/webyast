require "lib/resource"
  
# routing is generated from the 'resources' database table
# see config/initializers/resource_registration.rb for populating the database


# Don't route outside full Rails (e.g. when just running db:migrate)
ResourceRegistration.route_all if ENV["RAILS_ENV"]

$stderr.puts ActionController::Routing::Routes.routes if ENV["RAILS_ENV"] == "development"
