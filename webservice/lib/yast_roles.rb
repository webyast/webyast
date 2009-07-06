module YastRoles

  require 'polkit'
  include PolKit

private
  def user_roles(user)
    return session['services'] if session['user_roles']
      
    return [] unless File.exists?(USER_ROLES_CONFIG)
    
    IO.foreach( USER_ROLES_CONFIG ) do |line|
      line = line.chomp
      next if line[0] == "#"
      roles = line.split(/[\s,]+/)
      return roles if ( roles.size > 1 and roles[0] == user )
    end
    return []
  end

public

  def permission_check(action)
    return true if ENV["RAILS_ENV"] == "test"
    return false if self.current_account==nil || self.current_account.login.size == 0

    begin
       if polkit_check( action, self.current_account.login) == :yes
          logger.debug "Action: #{action} User: #{self.current_account.login} Result: ok"
          return true
       end
    rescue #caused by poolkit
       logger.error "ruby-polkit has returned an exception"
    end
    #checking roles
    roles = user_roles(self.current_account.login)
    roles.each do |role|
       begin
          if ( role != self.current_account.login and
               polkit_check( action, role) == :yes)
             logger.debug "Action: #{action} User: #{self.current_account.login} WITH role #{role} Result: ok"
             return true
          end
       rescue  #caused by poolkit
          logger.error "ruby-polkit has returned an exception"
       end
    end
    logger.debug "Action: #{action} User: #{self.current_account.login} Result: NOT granted"
    return false
  end
end
