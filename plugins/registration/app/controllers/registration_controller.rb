# = Registration controller
# Provides access to the registration of the system at NCC/SMT.
#class Registration::RegistrationController < ApplicationController
class RegistrationController < ApplicationController

  before_filter :login_required

  def create
    # POST to registration => run registration
    @registration = Registration.new({})

    # TODO overwrite context data if defined
    #@registration.set_context( { } )

    # TODO: parse post data and set the arguments
    # @registration.set_arguments( { } )

    ret = @registration.register
    headers["Status"] = "400 Bad Request" if ret == 3
  end

  def show
    # get registration status
    @registration = Registration.new( { } )
    @registration.get_config
    render :status
  end

  def index
  end

end
