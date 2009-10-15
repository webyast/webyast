# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'exceptions'

class ApplicationController < ActionController::Base

  before_filter :ensure_eulas

  rescue_from 'BackendException' do |exception|
      render :xml => exception, :status => 503
  end

  rescue_from 'InvalidParameters' do |exception|
      render :xml => exception, :status => 422 #422-resource invalid
  end

  include AuthenticatedSystem

  include YastRoles

  helper :all # include all helpers, all the time

  def ensure_eulas
    if ActionController::Routing.possible_controllers.include?("eulas") then
      raise EulaNotAcceptedException unless License.all_accepted?
    end
  end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => 'b8ebfaf489f039bccb691367daf9da63'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password
end
