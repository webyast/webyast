# = Registration controller
# Provides access to the registration of the system at NCC/SMT.

class Registration::RegistrationController < ApplicationController

  before_filter :login_required

  def create
    # POST to registration => run registration
    permission_check("org.opensuse.yast.modules.ysr.statelessregister")
    raise InvalidParameters.new :registration => "Missing" unless params.has_key?(:registration)

    @register = Register.new
    if params[:registration].has_key?(:arguments) &&  !params[:registration][:arguments].blank? 
    then
      @register.arguments = {}
       params[:registration][:arguments].each do |h|
         if h.class == Hash || h.class == HashWithIndifferentAccess
         then
           @register.arguments[ h['name'] ] = h['value'] if ( h['name'] && h['value'] )
         end
      end
    end

    #overwriting default options
    if params[:registration].has_key?(:options) && params[:registration][:options].is_a?(Hash)
      params[:registration][:options].each do |key, value|
        @register.context[key] = value if @register.context.has_key? key
      end
    end

    ret = @register.register
    if ret == "4"
      render :xml=>@register.to_xml( :root => "registration", :dasherize => false ), :status =>400 and return 
    elseif ret != 0
      render ErrorResult.error(404, 2, "Error while calling registration server.") and return
    end
  end

  def show
    permission_check("org.opensuse.yast.modules.ysr.getregistrationconfig")
    # get registration status
    @register = Register.new
    render :status
  end

  def index
  end

end
