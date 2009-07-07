#
# 
#

class PermissionsController < ApplicationController

  before_filter :login_required

  require "scr"

  private

  def get_permission_list(user_id, filter = nil)
    @permissions = []
    ret = Scr.instance.execute(["polkit-action"])
    return false unless ret && ret[:exit] == 0
    
    suse_string = "org.opensuse.yast."
    lines = ret[:stdout].split("\n") rescue []

    # a hash for mapping string 'permission name' => boolean 'granted'
    perms = Hash.new

    lines.each do |s|   
      if (s.include?( suse_string )) &&
	(filter.blank? || s.include?( filter ))
	# set 'not granted' default
	perms[s] = false
      end
    end

    ret = Scr.instance.execute(["polkit-auth", "--user", user_id, "--explicit"])
    return false unless ret && ret[:exit] == 0
    
    lines = ret[:stdout].split("\n") rescue []
    lines.each do |s|
      # ignore the rights which do not have the prefix, do not have any .policy file
      # or do not match the filter
      if (s.include?( suse_string )) && perms.has_key?(s) && (filter.blank? || s.include?( filter ))
	# update the value to 'granted' state
	perms[s] = true
      end
    end
    
    # convert the hash to a list of Permission objects
    @permissions = []
    perms.each do |name,value|
      permission = Permission.new 	
      permission.name = name
      permission.grant = value
      @permissions << permission
    end
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
    # user can always see his rights
    unless (permission_check( "org.opensuse.yast.permissions.read") || (!params[:user_id].blank? && self.current_account.login == params[:user_id]))
      render ErrorResult.error(403, 1, "no permission") and return
    end
    if params[:user_id].blank?
      render ErrorResult.error(404, 2, "user_id is not defined") and return
    end
    unless get_permission_list(params[:user_id], params[:filter])
      render ErrorResult.error(404, 2, "cannot get permission list") and return
    end
  end

  # GET /users/<uid>/permissions/<id>?user_id=<user_id>

  def show
    unless (permission_check( "org.opensuse.yast.permissions.read") || (!params[:user_id].blank? && self.current_account.login == params[:user_id]))
      render ErrorResult.error(403, 1, "no permission") and return
    end
    if params[:user_id].blank?
      render ErrorResult.error(404, 2, "user_id is not defined") and return
    end
    if params[:id].blank?
      render ErrorResult.error(404, 2, "right is not defined") and return
    end
    right = params[:id]
    @permission = Permission.new 	
    unless get_permission_list(params[:user_id])
      render ErrorResult.error(404, 1, "cannot get permission list") and return
    end
    for i in 0..@permissions.size-1
      if @permissions[i].name == right
        permission = @permissions[i]
        break
      end
    end
    if !permission || permission.name.blank?
      render ErrorResult.error(404, 1, "Permission: #{right} not found.") and return
    end

    respond_to do |format|
      format.json { render(:json => permission.to_json, :location => "none") }
      format.xml { render(:xml => permission, :location => "none") }
    end
  end

  # PUT /permissions/<user_id>
  # PUT /permissions/<user_id>.xml
  # PUT /permissions/<user_id>.json

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

    ret = Scr.instance.execute(["polkit-auth", "--user", params[:permissions][:id], params[:permissions][:grant] ? "--grant" : "--revoke", params[:permissions][:name]])
    if ret[:exit] != 0
      render ErrorResult.error(404, 1, ret[:stderr]) and return
    end
    permission = Permission.new(params[:permissions][:name], params[:permissions][:grant] )
    return render(:json => permission.to_json, :location => "none") if jsonFormat
    return render(:xml => permission, :location => "none")

  end

end
