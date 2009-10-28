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
  # check if the username is valid (letters, digits, underscores)
  #
  
  def username_valid? user
    user =~ /\A[\d\w_]+\z/
  end

  
  #
  # iterate over org.opensuse.yast permissions
  # user_name: if set, iterate over granted perms
  #          else iterate over all
  # filter:  optional filter string, i.e. "scr"
  #
  def each_suse_permissions( user_name, filter = nil )
    # filter org.opensuse.yast
    suse_string = /org\.opensuse\.yast\..*/
    
    # get users or all actions
    ret = if user_name
            Scr.instance.execute(["polkit-auth", "--user", user_name, "--explicit"])
          else
            Scr.instance.execute(["polkit-action"])
          end 

    ret[:stdout].scan(suse_string) do |p|
      next unless filter.blank? or p.include?(filter)
      yield p
    end

  end
  
  #
  # get all Array of Permissions user_id has
  #
  
  def permissions_list(user_name, filter = nil)

    # a hash for mapping string 'permission name' => boolean 'granted'
    perms = Hash.new
    
    # get all known permissions into 'perms' hash
    each_suse_permissions( nil, filter ) do |p|
      perms[p] = false
    end

    # now set those 'true' which are granted
    each_suse_permissions( user_name, filter ) do |p|
      perms[p] = true
    end
    
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
    user = params[:user_id]
    if user.blank?
      render ErrorResult.error(404, 2, "No user specified") and return
    end
    unless username_valid? user
      render ErrorResult.error(404, 2, "Bad user name specified: '#{user}'") and return
    end
    unless permissions_list(user, params[:filter])
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
    # allowed to update ?
    unless permission_check( "org.opensuse.yast.permissions.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    
    # valid user passed ?
    user = params[:id]
    if user.blank?
      render ErrorResult.error(404, 1, "user not found") and return
    end
    unless username_valid? user
      render ErrorResult.error(404, 1, "invalid user '#{user}'") and return
    end
    
    # requested format ?
    jsonFormat = false
    jsonFormat = true if user.end_with?(".json")
    if ( params[:permissions].blank? )
      render ErrorResult.error(404, 1, "no permissions found") and return
    end

    # valid permission passed ?
    name = params[:permissions][:name]
    unless name =~ /\A\w+(\.(\w+))*\z/
      render ErrorResult.error(404, 1, "invalid permission: '#{name}'") and return
    end

    grant = params[:permissions][:grant]

    ret = Scr.instance.execute(["polkit-auth", "--user", user.chomp(".xml"), grant ? "--grant" : "--revoke", name])

    if ret[:exit] != 0
      render ErrorResult.error(404, 1, ret[:stderr]) and return
    end
    permission = Permission.new(name, grant)
    return render(:json => permission.to_json, :location => "none") if jsonFormat
    return render(:xml => permission, :location => "none")

  end

end
