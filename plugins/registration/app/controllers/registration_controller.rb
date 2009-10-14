# = Registration controller
# Provides access to the registration of the system at NCC/SMT.
#class Registration::RegistrationController < ApplicationController
class RegistrationController < ApplicationController

  before_filter :login_required

  def create
    # POST to registration => run registration
    @registration = Registration.new({})

    # TODO: parse post data and set context data
    #@registration.set_context( { } )
    ret = @registration.register
  end

  def show
    # getRegistrationServerDetails

    @registration = Registration.new( { } )
    puts @registration.get_config.inspect
    render :status
    # do not run registration
    # only get the uuid, server url and certificate -> to be done in YSR.pm

  end

  def index
  end

end
