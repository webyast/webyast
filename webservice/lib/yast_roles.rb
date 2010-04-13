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

  # Shortcut for yapi permission so it is enought to write
  #    yapi_perm_check "time.read"
  # instead
  #    permission_check "org.opensuse.yast.modules.yapi.time.read"
  # for more details see permission_check
  def yapi_perm_check(action)
    permission_check "org.opensuse.yast.modules.yapi.#{action}"
  end

  # Check if permission user can do selected action. Check also roles in which user act.
  # <b>action</b>:: name of target action
  # <b>throws</b> :: throwed exceptions:
  #                  - _NotLoggedException_ if no user is logged
  #                  - _NoPermissionException_ if permission is not granted
  #                  - _PolicyKitException_ for error during running policy kit
  #
  def permission_check(action)
    account = self.current_account
    raise NotLoggedException if account.nil? || account.login.size == 0
    action ||= "" #avoid nil action

    begin
      if PolKit.polkit_check( action, account.login) == :yes
        Rails.logger.debug "Action: #{action} User: #{account.login} Result: ok"
        return true
      end
      #checking roles
      roles = (defined?(session) && session && session['user_roles']) ? session['services'] : user_roles(account.login)
      roles.each do |role|
        if ( role != account.login and
              PolKit.polkit_check( action, role) == :yes)
          Rails.logger.debug "Action: #{action} User: #{account.login} WITH role #{role} Result: ok"
          return true
        end
      end
      Rails.logger.debug "Action: #{action} User: #{account.login} Result: NOT granted"
      raise NoPermissionException.new(action, account.login)
    rescue RuntimeError => e
      puts "permission_check1: #{e}, #{account.inspect}:#{action}"
      Rails.logger.info e
      raise PolicyKitException.new(e.message, account.login, action)
    rescue Exception => e
      puts "permission_check2: #{e}"
      Rails.logger.info e
      raise
    end
  end
end
