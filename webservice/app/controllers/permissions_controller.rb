#
# Configure PolicyKit permissions for a user
#

class PermissionsController < ApplicationController

  before_filter :login_required

  def initialize
    @permissions = []
  end
  
  private
  
  #
  # check if logged in user requests his own stuff
  #
  def user_self( params )
    !params[:user_id].blank? && (params[:user_id] == self.current_account.login)
  end
  
  public

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------

  # permissions
  # GET /permissions/:user_id(.:format)

  def show
    unless user_self(params)
      permission_check "org.opensuse.yast.permissions.read"
    end
    permission = Permission.find(:all,params)
    respond_to do |format|
      format.json { render :json => permission.to_json }
      format.xml { render :xml => permission.to_xml }
    end
  end

  # change permissions
  # PUT /permissions/:id(.:format)
  # nested within users
  # PUT /users/:user_id/permissions/:id(.:format)

  def update

  #implementation is wrong so not mark as not implemented
  ret = { :error => "not implemented" }
    respond_to do |format|
      format.json { render :json => ret.to_json }
      format.xml { render :xml => ret.to_xml }
    end

  end

end
