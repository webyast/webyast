# = Registration controller
# Provides access to the registration of the system at NCC/SMT.
#class Registration::RegistrationController < ApplicationController
class RegistrationController < ApplicationController

  before_filter :login_required

  # @registration = Registration.new( { :doo => :daa } )


  def update
  end

  def create
    # POST to registration => run registration
    @registration = Registration.new({})

    # TODO: parse post data and set context data
    #@registration.set_context( { } )
    @registration.register

  end

  def show
    # getRegistrationServerDetails
    #@registration = @@registration
    #@registration = Registration.new( getRegistrationServerDetails.to_s )


    @registration = Registration.new( { } )
    # do not run registration
    # only get the uuid, server url and certificate -> to be done in YSR.pm

    #@registration.register
    #@registration = "GET to /registration/"
  end

  def index
  end

end
