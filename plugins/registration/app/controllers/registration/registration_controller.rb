# = Registration controller
# Provides access to the registration of the system at NCC/SMT.

class Registration::RegistrationController < ApplicationController

  before_filter :login_required

  def create
    # POST to registration => run registration
    permission_check("org.opensuse.yast.modules.ysr.statelessregister")

    @register = Register.new({})

    begin
      if request.env["rack.input"].size>0
        req = Hash.from_xml request.env["rack.input"].read
      else
        req = Hash.new
      end
    rescue
      req = Hash.new
    end



    valid_context_keys = %w[forcereg nooptional nohwdata yastcall norefresh logfile]
    context = Hash.new

    #puts req.inspect

    if req['registration'] &&
       req['registration']['options'] &&
       req['registration']['options'].is_a?(Hash)
      req['registration']['options'].each do |k, v|
        case k
          when 'debug'
            context['debugMode'] = v
          when 'restorerepos'
            context['restoreRepos'] = v
          else
            context[k] = v if valid_context_keys.include? k
        end
      end
    end

    puts context.inspect

    # overwrite context data
    @register.set_context( context )

    # TODO: parse post data and set the arguments
    # @register.set_arguments( { } )

    ret = @register.register
    #if (ret != 0)
    #  headers["Status"] = "400 Bad Request"
    #end
  end

  def show
    permission_check("org.opensuse.yast.modules.ysr.getregistrationconfig")
    # get registration status
    @register = Register.new( { } )
    @register.get_config
    render :status
  end

  def index
  end

end
