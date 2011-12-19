
require "yast_service"

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
      permission = Permission.find( perm, {:user_id => user.username})
      if permission.length >= 1
        granted = true if permission[0][:granted] 
      else
        #trying out pluralized class 
        perm = "org.opensuse.yast.modules.yapi.#{subject_class.to_s.pluralize.downcase}.#{action.to_s.downcase}"          
        permission = Permission.find( perm, {:user_id => user.username})
        granted = true if permission[0][:granted] 
      end
      if granted
        Rails.logger.debug "Action: #{perm} User: #{user.username} Result: ok"
      else
        Rails.logger.debug "Action: #{perm} User: #{user.username} Result: NOT granted"
      end
      granted
    end
  end
end
