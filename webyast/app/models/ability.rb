
class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    can do |action, subject_class, subject|
      action ||= "" #avoid nil action
      perm = "org.opensuse.yast.modules.yapi.#{subject_class.to_s.downcase}.#{action.to_s.downcase}"
      granted = false
      YastService.lock #locking for other thread
      begin
        if Permission.dbus_obj.check( [perm], user.username )[0][0] == "yes"
          Rails.logger.debug "Action: #{perm} User: #{user.username} Result: ok"
          granted = true
        else
          Rails.logger.debug "Action: #{perm} User: #{user.username} Result: NOT granted"
        end
      rescue Exception => e
        #trying out pluralized class 
        perm = "org.opensuse.yast.modules.yapi.#{subject_class.to_s.pluralize.downcase}.#{action.to_s.downcase}"          
        if Permission.dbus_obj.check( [perm], user.username )[0][0] == "yes"
          Rails.logger.debug "Action: #{perm} User: #{user.username} Result: ok"
          granted = true
        else
          Rails.logger.debug "Action: #{perm} User: #{user.username} Result: NOT granted"
        end
        unless granted
          Rails.logger.info e
          raise PolicyKitException.new(e.message, user.username, perm)
        end
      ensure
        YastService.unlock #unlocking for other thread
      end
      granted
    end
  end
end
