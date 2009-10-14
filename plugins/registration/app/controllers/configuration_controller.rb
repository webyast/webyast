# = RegistrationConfiguration controller
# Provides access to the configuration of the registration system
#class Registration::ConfigurationController < ApplicationController
class ConfigurationController < ApplicationController

  before_filter :login_required

  def update
    # PUT
    # setRegistrationServerDetails
    @registration = "PUT to /registration/configuration"
  end

  def show
    # do not run registration
    # only get the server url and certificate -> to be done in YSR.pm

    @registration = Registration.new( { } )
    puts @registration.get_config.inspect

  end

  def index
    @registration = "GET to INDEX  /registration/configuration"
  end

end
