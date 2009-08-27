module YastRoles

  require 'polkit'
  require 'exceptions'

  private
  def user_roles(user)
    IO.foreach( USER_ROLES_CONFIG ) do |line|
      line.chomp!
      next if line[0] == "#"
      roles = line.split(/[\s,]+/)
      return roles if ( roles.size > 1 and roles[0] == user )
    end if File.exists?(USER_ROLES_CONFIG)
    
    return []
  end

  public

  def permission_check(action)
    return true if ENV["RAILS_ENV"] == "test"
    raise NotLoggedException if self.current_account==nil || self.current_account.login.size == 0
    action ||= "" #avoid nil action

    begin
      if PolKit.polkit_check( action, self.current_account.login) == :yes
        Rails.logger.debug "Action: #{action} User: #{self.current_account.login} Result: ok"
        return true
      end
      #checking roles
      roles = (defined?(session) && session && session['user_roles']) ? session['services'] : user_roles(self.current_account.login)
      roles.each do |role|
        if ( role != self.current_account.login and
              PolKit.polkit_check( action, role) == :yes)
          Rails.logger.debug "Action: #{action} User: #{self.current_account.login} WITH role #{role} Result: ok"
          return true
        end
      end
      Rails.logger.debug "Action: #{action} User: #{self.current_account.login} Result: NOT granted"
      raise NoPermissionException.new(action, self.current_account.login)
    rescue RuntimeError => e
      Rails.logger.info e
      raise PolicyKitException.new(e.message, self.current_account.login, action)
    end
  end
end
