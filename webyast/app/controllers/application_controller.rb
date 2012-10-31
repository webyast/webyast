#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

require 'exceptions'
require 'dbus'
require 'haml_gettext' # translate haml file on the fly
require 'syslog'

class ApplicationController < ActionController::Base
  include FastGettext::Translation

  before_filter :format_check
  before_filter :authenticate_account!
  before_filter :set_gettext_locale
  before_filter :base_system

  # controllers allowed to be called when the base setup has not been finished yet
  SYSTEM_CONTROLLERS = ["controlpanel", "notifier", "sessions"]

  # This defines how the default Ability (for cancan, the
  # role based mechanism) is constructed
  def current_ability
    @current_ability ||= Ability.new(current_account)
  end

protected

  def format_check
    if (request.format.xml? || request.format.json?) && !Yast::Config.rest_api_enabled
      error_description = {:description => "REST API is not enabled in configuration file (/etc/webyast/config.yml)."}
      respond_to do |format|
        format.xml {render :xml => error_description.to_xml(:root => "error"), :status => 404}
        format.json{render :json => {"error" => error_description}.to_json, :status => 404}
      end
    else
      if !Yast::Config.web_ui_enabled
        if request.format.html?
          render 'main/disabled', :status => 404
        else
          # for all other formats just return 404 with empty data
          head :status => 404
        end
      end
    end
  end

  def redirect_success
    logger.debug session.inspect
    if Basesystem.new.load_from_session(session).in_process?
      logger.debug "wizard redirect DONE"
      redirect_to :controller => "/controlpanel", :action => "nextstep", :done => self.controller_name
    else
      logger.debug "Success non-wizard redirect"
      redirect_to :controller => "/controlpanel", :action => "index"
    end
  end

  # helper to add details show link with details content as parameter
  # Main usage is for flash message
  #
  # === usage ===
  # flash[:error] = "Fatal error."+details("really interesting details")
  def details(message, options={})
    ret = "<br><a href=\"#\" onClick=\"$('.details',this.parentNode.parentNode.parentNode).toggle();\"><small>#{_('details')}</small></a>
            <pre class=\"details\" style=\"display:none\"> #{CGI.escapeHTML message } </pre>"
    ret.html_safe
  end

public

  #render only pure text to simple show it on frontend
  rescue_from Exception, :with => :report_exception
  rescue_from BackendException, :with => :report_backend_exception
  rescue_from CanCan::AccessDenied do |exception|
    permission = "org.opensuse.yast.modules.yapi.#{exception.subject.to_s.downcase}.#{exception.action.to_s.downcase}"
    logger.info "No permission: #{permission}"
    if request.xhr? || request.format.html?
      flash[:error] = _("Operation is forbidden. If you have to do it, please contact system administrator")+
        details(exception.message + " (#{permission})" ) #already localized from error constructor
      if request.xhr?
        render :text => "<div>#{flash[:error]}</div>", :status => 403
      else
        redirect_to :controller => :controlpanel
      end
    else
      render :xml => exception, :status => 403 #403-forbidden
    end
  end

  rescue_from InvalidParameters do |exception|
    logger.info "Raised resource Invalid exception - #{exception.inspect}"
    render :xml => exception, :status => 422 #422-resource invalid
  end

  rescue_from DBus::Error do |exception|
    logger.info "Raised DBus::Error exception - #{exception.message}"
    logger.info "#{exception.inspect}"
    report_backend_exception DBusException.new(exception.message)
  end

#lazy load of YaST::Config library
  rescue_from "YaST::ConfigFile::NotFoundError" do |exception|
    #catch uncaught exception from reading yaml and report as
    #Backend problem
    logger.warn "Uncaught ConfigFile::NotFound exception. Reported as CorruptedFile"
    report_backend_exception CorruptedFileException.new(exception.path)

  end

  helper :all # include all helpers, all the time

private

  def report_backend_exception(exception)
      logger.info "Backend exception: #{exception}"
      report_exception(exception, 503)
  end

  def report_exception(exception, status = 500)
    logger.warn "Uncaught exception #{exception.class}: #{exception.message}"
    logger.warn "Backtrace: #{exception.backtrace.join('\n')}" unless exception.backtrace.blank?

    # for ajax request render a different template, much less verbose
    if request.xhr?
      logger.error "Error during ajax request"
      render :status => status, :partial => "shared/exception_trap", :locals => {:error => exception } and return
    end

    if request.format.html?
      case exception
      when ActionController::InvalidAuthenticityToken
        render :status => status, :template => "shared/cookies_disabled"
      else
        render :status => status, :template => "shared/exception_trap", :locals => {:error => exception}
      end
    else
      xml = Builder::XmlMarkup.new({})
      xml.instruct!

      xml.error do
        xml.type "GENERIC"
        xml.description exception.message
        xml.tag!(:bug,true,:type=> "boolean")
        xml.backtrace(:type => "array") do
          exception.backtrace.each do |b|
            xml.line b
          end
        end
      end

      render :xml => xml, :status => status
    end
  end

  def self.bug_url
    begin
      return VendorSetting.bug_url if VendorSetting.bug_url
    rescue Exception => vendor_excp
      # there was a problem or the setting does not exist
      # Here we should handle this always as an error
      # the service should return a sane default if the
      # url is not configured
      logger.warn "Can't get vendor bug reporting url, Using Novell. Exception: #{vendor_excp.inspect}"
    end
    #fallback if bugurl is not defined
    return "https://bugzilla.novell.com/enter_bug.cgi?product=WebYaST&format=guided"
  end

  # set the current locale
  # use URL ?locale=<locale> parameter, 'webyast_locale' cookie or HTTP_ACCEPT_LANGUAGE header value
  # fallback to en_US
  def set_gettext_locale
    # see https://github.com/grosser/fast_gettext
    I18n.locale = FastGettext.set_locale(params[:locale] || cookies[:webyast_locale] || request.env['HTTP_ACCEPT_LANGUAGE'] || 'en_US')
    Rails.logger.debug "Using locale: #{I18n.locale}"
    cookies[:webyast_locale] = I18n.locale if cookies[:webyast_locale] != I18n.locale.to_s
  end

  def after_sign_in_path_for(resource_or_scope)
    msg = "User \"#{current_account.username}\" logged in, remote IP: #{request.remote_ip}"
    Rails.logger.info msg
    # flags: log PID, log to console if syslog fails, it's a security message
    Syslog.open("WebYaST", Syslog::LOG_PID | Syslog::LOG_CONS | Syslog::LOG_AUTH) { |s| s.info msg }

    Rails.logger.info "Reading all permissions for #{current_account.username} again"
    Permission.reset(current_account.username)
    super
  end

  def after_sign_out_path_for(resource_or_scope)
    unless current_account.nil?
      msg = "User \"#{current_account.username}\" logged out, remote IP: #{request.remote_ip}"
      Rails.logger.info msg
      Syslog.open("WebYaST", Syslog::LOG_PID | Syslog::LOG_CONS | Syslog::LOG_AUTH) { |s| s.info msg }
    end
    super
  end

  # Checks if basic system module should be shown
  # and if it should, then also redirects to that module.
  # TODO check if controller from config exists
  def base_system
    first_run = !(Basesystem.new.load_from_session(session).initialized)
    bs = Basesystem.find(session)

    if !bs.completed?
      Rails.logger.debug "The base setup was not completed, first run: #{first_run}"

      # the current step is different than the requested controller
      # (but some specific controllers are allowed)
      if bs.current_step[:controller] != self.controller_name && !SYSTEM_CONTROLLERS.include?(self.controller_name)
        Rails.logger.info "Redirect needed: requested controller: #{self.controller_name.inspect}, current basesystem step: #{bs.current_step.inspect}"
        if first_run
          redirect_to bs.current_step
        else
          render "controlpanel/basesystem", :layout => !request.xhr?
        end
      end
    end
  end

end
