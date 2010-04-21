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

class ApplicationController < ActionController::Base

  #render only pure text to simple show it on frontend
  rescue_from Exception, :with => :report_exception

  rescue_from BackendException, :with => :report_backend_exception

  rescue_from InvalidParameters do |exception|
    logger.info "Raised resource Invalid exception - #{exception.inspect}"
    render :xml => exception, :status => 422 #422-resource invalid
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
end
