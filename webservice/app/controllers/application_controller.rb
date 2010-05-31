#--
# Webyast Webservice framework
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

class ApplicationController < ActionController::Base

  #render only pure text to simple show it on frontend
  rescue_from Exception, :with => :report_exception

  rescue_from BackendException, :with => :report_backend_exception

  rescue_from NoPermissionException do |exception|
    logger.info "No permission: #{exception.permission} for #{exception.user}"
    render :xml => exception, :status => 403 #403-forbidden
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
  filter_parameter_logging :password

  private
  def report_backend_exception(exception) 
      logger.info "Backend exception: #{exception}"
      render :xml => exception, :status => 503
  end

  def report_exception(exception)
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
    logger.warn "Uncaught exception: #{exception.message} \n Backtrace: #{exception.backtrace.join('\n')}"
      
    render :xml => exception, :status => 500
    
  end

  def init_gettext(domainname, language, options = {})
    locale_path = options[:locale_path]
    unless locale_path
      #If path of the translation has not been set we are trying to default translations
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
    else
      #load default if the path has been given
      logger.info "Loading textdomain #{domainname} from #{locale_path}"
      ActionController::Base.init_gettext(domainname, options)
    end
    languages = Dir[ File.join(locale_path, '*') ].collect{|v| File.basename(v)}
    I18n.supported_locales = languages
    logger.info "Supported languages: #{languages.inspect}"
  end


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


end
