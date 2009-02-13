# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  include AuthenticatedSystem

begin
  require 'polkit'
  include PolKit
rescue Exception => e
  $stderr.puts "ruby-polkit not found!"
  exit
end

private
  def user_roles(user)
    if session['user_roles'] == nil
       IO.foreach( "/etc/yast_user_roles" ) { |line|
          line = line.chomp
          if (line.size >= 1 and
              line[0] != "#" ) #no comment
             roles = line.split(/[\s,]+/)
             if ( roles.size > 1 and
                  roles[0] == user )
                return roles
             end
          end
       }
       return []
    else
       return session['services']
    end
  end

public

  def permission_check(action)
    if self.current_account==nil || self.current_account.login.size == 0
       return false
    end
    if polkit_check( action, self.current_account.login) == :yes
       logger.debug "Action: #{action} User: #{self.current_account.login} Result: ok"
       return true
    else
       #checking roles
       roles = user_roles(self.current_account.login)
       roles.each do |role|
          if ( role != self.current_account.login and
               polkit_check( action, role) == :yes)
             logger.debug "Action: #{action} User: #{self.current_account.login} WITH role #{role} Result: ok"
             return true
          end
       end
    end
    logger.debug "Action: #{action} User: #{self.current_account.login} Result: NOT granted"
    return false
  end

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => 'b8ebfaf489f039bccb691367daf9da63'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password
end
