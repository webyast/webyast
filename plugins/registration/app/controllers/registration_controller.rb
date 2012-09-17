#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

# = Registration controller
# Provides access to the registration of the system at NCC/SMT.

class RegistrationController < ApplicationController
  include ERB::Util

  def initialize
    # FIXME: use a constant here (see https://github.com/webyast/webyast/wiki/Localization)
    @trans = {  'email' => _("Email"),
                'moniker' => _("System name"),
                'regcode-sles' => _("SLES registration code"),
                'regcode-sled' => _("SLED registration code"),
                'regcode-slms' => _("SLMS registration code"),
                'regcode-sms' => _("SUSE Manager Server registration code"),
                'regcode-smp' => _("SUSE Manager Proxy registration code"),
                'appliance-regcode' => _("Appliance registration code"),
                'regcode-webyast'   => _("WebYaST registration code"),
                '___getittranslated1' => _("Registration code"),
                '___getittranslated2' => _("Hostname"),
                '___getittranslated3' => _("Device name"),
                '___getittranslated4' => _("Appliance name"),
                '___getittranslated5' => _("registration code")
             }
    @trans.freeze
    @options = { 'debug'=>2 , 'forcereg' => 0 }
  end

  private

  def translate_argument_key(key)
    return _('[empty]') unless key
    return @trans[key] if @trans[key]
    key
  end

  def sort_arguments(args)
    begin
      args.collect! do |arg|
        arg['description'] = translate_argument_key( arg.kind_of?(Hash) ? arg['name'] : nil )
        arg
      end
      # sort by names alphabetically
      return args.sort! { |a,b|  a['name'] <=> b['name'] }
    rescue
      return Array.new
    end
  end

  def client_guid
    # handle config error in backend (bnc#592620)
    guid = nil
    config_error = false
    begin
      status = Register.new()
      guid = status.guid
      config_error status.config_error
      logger.debug "found GUID: #{guid}"
    rescue
      logger.debug "Registration could not find registration information: system is unregistered." # RORSCAN_ITL
    end
    return guid, config_error
  end

  def try_again_msg
    _("Please try to register again later.")
  end

  def not_succeeded_msg
    _("Registration did not succeed.")
  end

  def skipped_msg
    _("Registration was skipped.")
  end

  def temporary_issue_msg
    _("This may be a temporary issue.")
  end

  def no_updates_msg
    _("The system might not receive necessary updates.") # RORSCAN_ITL
  end

  def registration_skip_flash
    "<b>#{ h skipped_msg }</b><p>#{ h no_updates_msg }<br />#{ h try_again_msg }</p>".html_safe
  end

  def server_error_flash(msg)
    "<b>#{ h not_succeeded_msg }</b><p>#{ msg || '' } #{ h temporary_issue_msg }<br />#{ h try_again_msg }</p>".html_safe
  end

  def data_error_flash(msg)
    "<b>#{ h not_succeeded_msg }</b><p>#{ msg || h(try_again_msg) }</p>".html_safe
  end

  def registration_logic_error
    flash[:error] = server_error_flash _("The registration server returned invalid or incomplete data.")
    logger.error "Registration resulted in an error, registration server or SuseRegister backend returned invalid or incomplete data."
    # success: allow users to skip registration in case of an error (bnc#578684) (bnc#579463)
    redirect_success
  end

  def registration_backend_error
    logger.error "Registration could not read the configuration. Most likely the backend is not installed correctly. Please check the package dependencies."
    flash[:error] = (_("Could not read the registration configuration.") + "<br>" + _("The registration backend is not installed correctly") +
                    " " + _("Please refer to your support contact.")).html_safe
  end

  def collect_missing_arguments(missed_args)
    arg_error_count = 0
    begin
      @arguments.collect! do |argument|
        missed_args.each do |missed_arg|
          if missed_arg["name"] == argument["name"] then
            if argument["value"] != missed_arg["value"] then
              # flag error if value is rejected by registration server
              argument["error"] = true if missed_arg["flag"] == "m"
              arg_error_count += 1
            end
            argument["value"] = missed_arg["value"]
            argument["flag"] = missed_arg["flag"]
            argument["kind"] = missed_arg["kind"]
            missed_args.reject! {|del_arg| del_arg["name"] == argument["name"] }
            break
          end
        end
        argument
      end
    rescue
      logger.error "Registration process can not collect the argument details."
    end

    # add remaining arguments to the list
    @arguments.concat(missed_args)
    flash[:error] = _("Please fill out missing entries.") if arg_error_count > 0
  end

  def split_arguments
    begin
      # split arguments into two lists to show them separately and sort each list to show them in a unique order
      @arguments_mandatory = sort_arguments( @arguments.select { |arg| (arg["flag"] == "m") if arg.kind_of?(Hash) } )
      @arguments_automatic = sort_arguments( @arguments.select { |arg| (arg["flag"] == "a") if arg.kind_of?(Hash) } )
      @arguments_detail    = sort_arguments( @arguments.select { |arg| ( (arg["flag"] != "m") && (arg["flag"] != "a") ) if arg.kind_of?(Hash) } )
    rescue
      logger.error "Registration found invalid argument data. Nothing to display to the user."
      @arguments_mandatory = []
      @arguments_automatic = []
      @arguments_detail = []
    end
  end

  def sources_changes_flash(msg=''.html_safe)
    # use an own type for this message
    # because it needs to be displayed and bypass the UI-expert-filter (bnc600842)
    ftype = :repoinfo
    flash[ftype] ||= ''.html_safe
    flash[ftype] += msg
  end

  def check_service_changes(changed_services) 
    begin
      changes = false
      if changed_services.size > 0 then
        flash_msg = "<ul>"
        changed_services.each do |c|
          if !c[:name].blank? && c[:status] == 'added' then
            flash_msg += "<li>" + h(_("Service added: %s") % c[:name]) + "</li>"
          end
          unless c[:catalogs].blank?
            flash_msg += "<ul>"
            c[:catalogs].each do |s|
              if s[:status] == 'added' then
                flash_msg += "<li>" + h(_("Catalog enabled: %s") % s[:name]) + "</li>"
                changes = true
              end
            end
            flash_msg += "</ul>"
          end
        end
        flash_msg += "</ul>"
        sources_changes_flash flash_msg.html_safe if changes
      else
        return false
      end
    rescue
      logger.error "Registration could not check the services for changes."
      return false
    end
    true
  end

  def check_repository_changes(changed_repositories)
    begin
      changes = false
      if changed_repositories.size > 0 then
        flash_msg = "<ul>"
        changed_repositories.each do |r|
          if r[:status] == 'added' then
            flash_msg += "<li>" + h(_("Repository added: %s") % r[:name]) + "</li>"
            changes = true
          end
        end
        flash_msg += "</ul>"
        sources_changes_flash flash_msg.html_safe if changes
      else
        return false
      end
    rescue
      logger.error "Registration could not check the repositories for changes."
      return false
    end
    true
  end

public

  def skip
    authorize! :statelessregister, Register
    # redirect to the appropriate next target and show skip message
    guid, error = client_guid
    flash[:warning] = registration_skip_flash unless guid
    redirect_success
    return
  end

  def reregister
    # provide a way to force a new registration, even if system is already registered
    @nexttarget = 'reregisterupdate'
    # correctly set the forcereg parameter according to registration protocol specification
    @options['forcereg'] = 1

    register(reregister = true)
  end

  def reregisterupdate
    # update function for reregistration mode - adaption for (bnc#631173)
    #   in reregistration mode only the first request should contain the "forcereg" option
    #   the following should not contain them. The "update" function would stop the registration, as the system is already registered.
    @nexttarget = 'reregisterupdate'
    # no forcereg parameter here

    register(reregister = true)
  end

  def update
    @nexttarget = 'update'
    register
  end


  def create
    # POST to registration => run registration
    authorize! :statelessregister, Register
    raise InvalidParameters.new :registration => "Passed none or invalid data to registration" unless params.has_key?(:registration)

    # get new registration object
    @register = Register.new
    @register.arguments = {}

    # parse and set registration arguments
    if ( params && params.has_key?(:registration) &&
         params[:registration] && params[:registration].has_key?(:arguments) )
    then
      args = params[:registration][:arguments]
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
        @register.context[key] = value
      end
    end
    ret = @register.register
    if ret != 0
      render :xml=>@register.to_xml( :root => "registration", :dasherize => false ), :status => 400 and return
    end
  end

  def show
    authorize! :getregistrationconfig, Register
    # get registration status
    @register = Register.new
    respond_to do |format|
      format.xml { render  :xml => @register.status_to_xml( :dasherize => false ) }
      format.html { render :xml => @register.status_to_xml( :dasherize => false ) }
      format.json { render :json => @register.status_to_json.to_json }
    end
  end

  def index
    authorize! :statelessregister, Register
    guid, config_error = client_guid
    if config_error
      registration_backend_error
      redirect_success
      return
    end
    unless guid
      @arguments = []
      @nexttarget = 'update'
      register
    else
      @showstatus = true
    end
  end

  def reregister
    # provide a way to force a new registration, even if system is already registered
    @reregister = true
    @nexttarget = 'reregisterupdate'
    # correctly set the forcereg parameter according to registration protocol specification
    @options['forcereg'] = 1

    register
  end

  def register
    authorize! :getregistrationconfig, Register
    guid,config_error = client_guid
    if config_error
      registration_backend_error
      redirect_success
      return
    end

    # redirect in case of interrupted basesetup
    if guid && !@reregister
      flash[:warning] = _("This system is already registered.") # RORSCAN_ITL
      redirect_success
      return
    end

    # get new registration object
    register = Register.new
    register.arguments = {}
    begin
      params.each do | key, value |
        if key.starts_with? "registration_arg_"
          register.arguments[key[17, key.size-17]] = value
        end
      end
    rescue
      logger.debug "No arguments were passed to the registration call."
    end

    success = false
    begin
      register.context = @options
      exitcode = register.register
      logger.debug "registration finished: #{register.to_xml}"

      if register.status == "finished" then
        flash[:notice] = _("Registration finished successfully.")
        success = true
      elsif register.status == "missinginfo" && !register.missingarguments.blank?
        logger.debug "missing arguments #{register.missingarguments.inspect}"
        logger.info "Registration is in needinfo - more information is required"
        # collect and merge the argument data
        @arguments = []
        collect_missing_arguments register.missingarguments
      elsif register.status == "error"
        logger.error "Registration resulted in an error, ID: #{exitcode}."
        case exitcode
        when 199 then
          # 199 means that even the initialization of the backend did not succeed
          logger.error "Registration backend could not be initialized. Maybe due to network problem, SSL certificate issue or blocked by firewall."
          flash[:error] = server_error_flash _("A connection to the registration server could not be established.")
        when  2 then
          logger.error "Registration failed due to invalid data passed to the registration server. Most likely due to a wrong regcode."
          logger.error "  The registration server thus rejected the registration. User can try again."
          dataerror = _("The supplied registration data was invalid.")
          if ( !register.invaliddataerrormessage.blank?  &&
                ( register.invaliddataerrormessage.to_s.match /(invalid regcode)|(improper code was supplied)/i )  ) then
            logger.error "  Yep, the registration server says that the regcode was wrong."
            dataerror = _("The registration code you entered was invalid.")
          end
          flash[:error] = data_error_flash  "#{ dataerror }<br />#{ _("Please perform the registration again with correct registration data.") }"
        when  3 then
          # 3 means that there is a conflict with the sent and the required data - it could not be solved by asking again
          logger.error "Registration data is conflicting. Contact your vendor."
          flash[:error] = server_error_flash _("The transmitted registration data created a conflict.")
        when 99 then
          # 99 is an internal error id for missing error status or missing exit codes
          logger.error "Registration backend sent no or invalid data. Maybe network problem or slow connection or too much load on registration server."
          return registration_logic_error
        when 100..101 then
          # 100 and 101 means that no product is installed that can be registered (100: no product, 101: FACTORY)
          logger.error "Registration process did not find any products that can be registered."
          flash[:error] = ("<b>" + _("Registration can not be performed. There is no product installed that can be registered.") + "</b>").html_safe
        else
          # unknown error
          logger.error "Registration backend returned an unknown error. Please run in debug mode and report a bug."
          return registration_logic_error
        end
        redirect_success
        return
      else
        logger.debug "error while registration: #{error.inspect}"
        logger.error "Registration resulted in an error: Server returned invalid data"
        return registration_logic_error
      end
    rescue Exception => e
      logger.error "Registration is in error mode but no error status information is provided from the backend."
      logger.debug "Error from registration backend: #{e.inspect}"
      return registration_logic_error
    end

    if success
      logger.info "Registration succeed"
      # display warning if no repos/services are added/changed during registration(bnc#558854)
      if !check_service_changes(register.changedservices) && !check_repository_changes(register.changedrepos)
      then
        flash[:warning] = (_("<p><b>Repositories were not modified during the registration process.</b></p><p>It is likely that an incorrect registration code was used. If this is the case, please attempt the registration process again to get an update repository.</p><p>Please make sure that this system has an update repository configured, otherwise it will not receive updates.</p>")).html_safe # RORSCAN_ITL
      end

      redirect_success
    else
      logger.info "Registration is not yet finished"

      # split into madatory and detail arguments
      split_arguments

      if @arguments_mandatory.blank? && @arguments_detail.blank? then
        # redirect if the registration server is in needinfo but arguments list is empty
        flash[:error] = server_error_flash _("The registration server returned invalid data.")
        logger.error "Registration resulted in an error: Logic issue, unspecified data requested by registration server"
        redirect_success
        return
      end

      render :action => "index"
    end
  end

end
