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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'exceptions'
require 'gettext_rails'
require 'dbus'
require 'url_rewriter' #monkey patch for url_for with port

class ApplicationController < ActionController::Base
  layout 'main'  

protected
  def redirect_success
    logger.debug session.inspect
    if Basesystem.new.load_from_session(session).in_process?
      logger.debug "wizard redirect DONE"
      redirect_to :controller => "controlpanel", :action => "nextstep", :done => self.controller_name
    else
      logger.debug "Success non-wizard redirect"
      redirect_to :controller => "controlpanel", :action => "index"
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
    ret
  end

public

  #render only pure text to simple show it on frontend
  rescue_from Exception, :with => :report_exception

  rescue_from BackendException, :with => :report_backend_exception

  rescue_from NoPermissionException do |exception|
    logger.info "No permission: #{exception.permission} for #{exception.user}"
    if request.xhr? || request.format.html?
      flash[:error] = _("Operation is forbidden. If you have to do it, please contact system administrator")+
                          details(exception.message) #already localized from error constructor
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

  include AuthenticatedSystem

  include YastRoles

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => 'b8ebfaf489f039bccb691367daf9da63'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password # RORSCAN_ITL
  before_filter :init_cache

  private

  def init_cache(controller_name = request.parameters["controller"])
    return unless (logged_in? && YastCache.active) #Does not make sense if no session id is available or
                                                   #cache is not active
    if request && request.request_method == :get
      return unless (request.parameters["action"] == "show" || 
                     request.parameters["action"] == "index")
      #finding the correct cache name 
      #(has to be the model class name and not the controller name)
      path = YastCache.find_key(controller_name, (request.parameters["id"] || :all))
      if path.blank?
        logger.info("Cache for model #{path} not found")
        return
      end
      data_cache = DataCache.find_by_path_and_session(path, self.current_account.remember_token)
      found = false
      data_cache.each { |cache|
        found = true
        if cache.picked_md5 != cache.refreshed_md5
          cache.picked_md5 = cache.refreshed_md5
          cache.save
        end
      } unless data_cache.blank?
      DataCache.create(:path => path, :session => self.current_account.remember_token,
                       :picked_md5 => nil, :refreshed_md5 => nil) unless found
    end
  end

  def report_backend_exception(exception) 
      logger.info "Backend exception: #{exception}"
      report_exception(exception, 503)
  end

  def report_exception(exception, status = 500)
    def exception.to_xml
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
    end
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
      render :xml => exception, :status => status
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

protected

  def ensure_login
    unless logged_in?
      flash[:notice] = _("Please login to continue")
      redirect_to :controller => "session", :action => "new"
    end
  end

  def ensure_logout
    if logged_in?
      flash[:notice] = _("You must logout before you can login")
      redirect_to root_url
    end
  end

  def self.init_gettext(domainname, options = {})
    locale_path = options[:locale_path]
    unless locale_path
      #If path of the translation has not been set we are trying to load
      #vendor specific translations too
      if Dir.glob(File.join("**", "public", "**", "#{domainname}.mo")).size > 0
        vendor_text_path = "public/vendor/text/locale"
        locale_path = File.join(RAILS_ROOT, vendor_text_path)
        opt = {:locale_path => locale_path}.merge(options)
        logger.info "Loading textdomain #{domainname} from #{vendor_text_path}"
        ActionController::Base.init_gettext(domainname, opt)
      else
        #load default no vendor translation available
        locale_path = ""
        #searching in RAILS_ROOT
        mo_files = Dir.glob(File.join(RAILS_ROOT, "**", "#{domainname}.mo"))
        if mo_files.size > 0
          locale_path = File.dirname(File.dirname(File.dirname(mo_files.first)))
        else
          # trying plugin directory in the git 
          mo_files = Dir.glob(File.join(RAILS_ROOT, "..", "**", "#{domainname}.mo"))
          locale_path = File.dirname(File.dirname(File.dirname(mo_files.first))) if mo_files.size > 0
        end
        unless locale_path.blank?
          logger.info "Loading standard textdomain #{domainname} from #{locale_path}"
          opt = {:locale_path => locale_path}.merge(options)
          ActionController::Base.init_gettext(domainname, opt)
        else
          logger.error "Cannot find translation for #{domainname}"
        end
      end
    else
      #load default if the path has been given
      logger.info "Loading textdomain #{domainname} from #{locale_path}"
      ActionController::Base.init_gettext(domainname, options)
    end
  end



  # Initialize GetText and Content-Type.
  # You need to call this once a request from WWW browser.
  # You can select the scope of the textdomain.
  # 1. If you call init_gettext in ApplicationControler,
  #    The textdomain apply whole your application.
  # 2. If you call init_gettext in each controllers
  #    (In this sample, blog_controller.rb is applicable)
  #    The textdomains are applied to each controllers/views.
  init_gettext "webyast-base"  # textdomain, options(:charset, :content_type)
  I18n.supported_locales = Dir[ File.join(RAILS_ROOT, 'locale/*') ].collect{|v| File.basename(v)}

=begin
  # You can set callback methods. These methods are called on the each WWW request.
  def before_init_gettext(cgi)
    p "before_init_gettext"
  end
  def after_init_gettext(cgi)
    p "after_init_gettext"
  end
=end


=begin
  # you can redefined the title/explanation of the top of the error message.
  ActionView::Helpers::ActiveRecordHelper::L10n.set_error_message_title(N_("An error is occured on %{record}"), N_("%{num} errors are occured on %{record}"))
  ActionView::Helpers::ActiveRecordHelper::L10n.set_error_message_explanation(N_("The error is:"), N_("The errors are:"))
=end
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'b1aeb693a1ee49ab70c6b6bf514963a3' RORSCAN_ITL

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password # RORSCAN_ITL

  # Translation mapping for ActiveResource validation errors
  def error_mapping
    # TODO: is it complete?
    # ActiveRecord::Errors.default_error_messages defines more messages
    # but it seems that they cannot be used with YaST model...
    {
      :blank => _("can't be blank"),
      :inclusion => _("is out of allowed values"),
      :empty => _("can't be empty"),
      :invalid => _("is invalid")
    }
  end


end
