# = Registration controller
# Provides access to the registration of the system at NCC/SMT.

class Registration::RegistrationController < ApplicationController

  before_filter :login_required

  def create
    # POST to registration => run registration
    permission_check("org.opensuse.yast.modules.ysr.statelessregister")
    raise InvalidParameters.new :registration => "Missing" unless params.has_key? :registration

    @register = Register.new({})
    @register.arguments = params[:registration][:arguments] if params[:registration].has_key? :arguments && 
                                                               !params[:registration][:arguments].blank?

    #overwriting default options
    if params[:registration].has_key? :options && params[:registration][:options].is_a?(Hash)
      params[:registration][:options].each do |key, value|
        @register.context[key] = value if @register.context.has_key? key
      end
    end

    ret = @register.register
    #if (ret != 0)
    #  headers["Status"] = "400 Bad Request"
    #end
  end

  def show
    permission_check("org.opensuse.yast.modules.ysr.getregistrationconfig")
    # get registration status
    @register = Register.new({})
    render :status
  end

  def index
  end

end
