include ApplicationHelper

class GroupsController < ApplicationController
  
  before_filter :login_required

  def initialize
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    yapi_perm_check "users.groupsget"
    begin
      # try to find the grouplist, and 404 if it does not exist
      @group = Group.find
      if @group.nil?
        render ErrorResult.error(404, 2, "grouplist not found") and return
      end
    rescue Exception => e
      render ErrorResult.error(500, 2, e.message) and return
    end

  end


end

