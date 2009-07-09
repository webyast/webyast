#
# Configure PolicyKit permissions for a user
#

class PermissionsController < ApplicationController

  before_filter :login_required

  require "scr"

  def initialize
    @permissions = []
  end
  
  private
  
  #
  # iterate over org.opensuse.yast permissions
  # user_id: if set, iterate over granted perms
  #          else iterate over all
  # filter:  optional filter string, i.e. "scr"
  #
  def each_suse_permissions( user_id, filter = nil )
    # filter org.opensuse.yast
    suse_string = /org\.opensuse\.yast\..*/
    
    # get users or all actions
    ret = if user_id
            Scr.instance.execute(["polkit-auth", "--user", user_id, "--explicit"])
	  else
	    Scr.instance.execute(["polkit-action"])
	  end rescue nil
    raise RuntimeError unless ret && ret[:exit] == 0

    ret[:stdout].scan(suse_string) do |p|
      next unless filter.blank? or p.include?(filter)
      yield p
    end

  end
  
  #
  # get all Array of Permissions user_id has
  #
  
  def permissions_list(user_id, filter = nil)

    # a hash for mapping string 'permission name' => boolean 'granted'
    perms = Hash.new
    
    # get all known permissions into 'perms' hash
    each_suse_permissions( nil, filter ) do |p|
      perms[p] = false
    end rescue return false

    # now set those 'true' which are granted
    each_suse_permissions( user_id, filter ) do |p|
      perms[p] = true
    end rescue return false
    
    # convert the hash to a list of Permission objects
    @permissions = []
    perms.each do |name,grant|
      permission = Permission.new name, grant
      @permissions << permission
    end
    true
  end

  #
  # check if logged in user requests his own stuff
  #
  def user_self( params )
    !params[:user_id].blank? && (params[:user_id] == self.current_account.login)
  end
  
  #
  # check params and fill @permissions
  #
  def retrieve_permissions( params )
    # user can always see his rights
    unless permission_check( "org.opensuse.yast.permissions.read") || user_self(params)
      render ErrorResult.error(403, 1, "no permission") and return
    end
    if params[:user_id].blank?
      render ErrorResult.error(404, 2, "No user specified") and return
    end
    unless permissions_list(params[:user_id], params[:filter])
      render ErrorResult.error(404, 2, "cannot get permission list") and return
    end
    true
  end
  
  public

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------

  # GET /permissions?user_id=<user_id>&filter=<filter>
  # GET /permissions.xml?user_id=<user_id>&filter=<filter>
  # GET /permissions.json?user_id=<user_id>&filter=<filter>

  def index
    retrieve_permissions params
  end

  # permissions
  # GET /permissions/:id(.:format)
  #
  # nesting within users
  # GET /users/:user_id/permissions/:id(.:format)

  def show
    right = params[:id]
    if right.blank?
      render ErrorResult.error(404, 2, "right is not defined") and return
    end
    
    retrieve_permissions(params) or return
    
    permission = nil
    @permissions.each do |p|
      next unless p.name == right
      permission = p
      break
    end
    if permission.nil? || permission.name.blank?
      render ErrorResult.error(404, 1, "Permission: #{right} not found.") and return
    end

    respond_to do |format|
      format.json { render(:json => permission.to_json, :location => "none") }
      format.xml { render(:xml => permission, :location => "none") }
    end
  end

  # change permissions
  # PUT /permissions/:id(.:format)
  # nested within users
  # PUT /users/:user_id/permissions/:id(.:format)

  def update
    unless permission_check( "org.opensuse.yast.permissions.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    if params[:id].blank?
      render ErrorResult.error(404, 1, "user not found") and return
    end
    jsonFormat = false
    jsonFormat = true if params[:id].end_with?(".json")
    if ( params[:permissions].blank? )
      render ErrorResult.error(404, 1, "no permissions found") and return
    end

    ret = Scr.instance.execute(["polkit-auth", "--user", params[:id], params[:permissions][:grant] ? "--grant" : "--revoke", params[:permissions][:name]])

    if ret[:exit] != 0
      render ErrorResult.error(404, 1, ret[:stderr]) and return
    end
    permission = Permission.new(params[:permissions][:name], params[:permissions][:grant] )
    return render(:json => permission.to_json, :location => "none") if jsonFormat
    return render(:xml => permission, :location => "none")

  end

end
