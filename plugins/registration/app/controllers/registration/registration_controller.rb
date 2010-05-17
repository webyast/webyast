# = Registration controller
# Provides access to the registration of the system at NCC/SMT.

class Registration::RegistrationController < ApplicationController

  before_filter :login_required

  def create
    # POST to registration => run registration
    permission_check("org.opensuse.yast.modules.ysr.statelessregister")
    raise InvalidParameters.new :registration => "Passed none or invalid data to registration" unless params.has_key?(:registration)

    # get new registration object
    @register = Register.new
    @register.arguments = {}

    # parse and set registration arguments
    if ( params && params.has_key?(:registration) &&
         params[:registration] && params[:registration].has_key?(:arguments) &&
         params[:registration][:arguments] && params[:registration][:arguments].has_key?(:argument) )
    then
      args = params[:registration][:arguments][:argument]
      case args
      when Array
        args.each do |item|
          @register.arguments[item['name'].to_s] = item['value'].to_s if item.has_key?(:name) && item.has_key?(:value)
        end
      when Hash, HashWithIndifferentAccess
        @register.arguments[args['name'].to_s] = args['value'].to_s if args.has_key?(:name) && args.has_key?(:value)
      else
        Rails.logger.info "Registration attempt without any valid registration data."
      end
    else
      Rails.logger.info "Registration attempt without any registration data."
    end


    #overwriting default options
    if params[:registration].has_key?(:options) && params[:registration][:options].is_a?(Hash)
      params[:registration][:options].each do |key, value|
        @register.context[key] = value if @register.context.has_key? key
      end
    end

    ret = @register.register
    if ret != 0
      render :xml=>@register.to_xml( :root => "registration", :dasherize => false ), :status => 400 and return
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
