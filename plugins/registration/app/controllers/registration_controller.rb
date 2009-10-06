# = Registration controller
# Provides access to the registration of the system at NCC/SMT.
class RegistrationController < ApplicationController

  before_filter :login_required
  @@registration = Registration.new('I am a registered machine (or not)')

  def update
  end

  def create
    # POST to registration => run registration

  end

  def show
    @registration = @@registration
  end


end
