# = Registration controller
# Provides access to the registration of the system at NCC/SMT.
#class Registration::RegistrationController < ApplicationController
class RegistrationController < ApplicationController

  before_filter :login_required

  # @@registration = Registration.new( { :doo => :daa } )


  def update
  end

  def create
    # POST to registration => run registration
    @registration = Registration.new( { } )
    @registration.register

    # @registration = "POST to /registration/ ... so we run the registration"
  end

  def show
    # getRegistrationServerDetails
    #@registration = @@registration
    #@registration = Registration.new( getRegistrationServerDetails.to_s )

    # 
    @registration = Registration.new( { } )
    @registration.register
    #@registration = "GET to /registration/"
  end

  def index
  end

end
