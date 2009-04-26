class PermissionsController < ApplicationController

  before_filter :login_required

  require "scr"

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------


  def get_permission_list(user_id)
     @permissions = []
     if permission_check( "org.opensuse.yast.webservice.read-permissions")
       ret = Scr.execute(["polkit-action"])
       if ret[:exit] == 0
          suse_string = "org.opensuse.yast.webservice."
          lines = ret[:stdout].split "\n"
          lines.each do |s|   
             if s.include? suse_string
                perm = s.slice( suse_string.size, s.size-1)
                permission = Permission.new 	
                permission.name = perm
                permission.grant = false
                permission.error_id = 0
                permission.error_string = ""
                @permissions << permission
             end
          end
          ret = Scr.execute(["polkit-auth", "--user", user_id, "--explicit"])
          if ret[:exit] == 0
             lines = ret[:stdout].split "\n"
             lines.each do |s|   
                   if s.include? suse_string
                   perm = s.slice( suse_string.size, s.size-1)
                   for i in 0..@permissions.size-1
                      if @permissions[i].name == perm
                         @permissions[i].grant = true
                         break
                      end
                   end
                end
             end
          else
             @permissions = []
             permission = Permission.new 	
             permission.error_id = 2
             permission.error_string = "user not found"
             @permissions << permission
          end
       else
          permission = Permission.new 	
          permission.error_id = 2
          permission.error_string = "cannot get permission list"
          @permissions << permission
       end

    else
       permission = Permission.new 	
       permission.error_id = 1
       permission.error_string = "no permission"
       @permissions << permission
    end
  end

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------

  # GET /users/<uid>/permissions
  # GET /users/<uid>/permissions.xml
  # GET /users/<uid>/permissions.json

  def index
    get_permission_list(params[:user_id])

    respond_to do |format|
      format.html { render :xml => @permissions, :location => "none" } #return xml only
      format.xml  { render :xml => @permissions, :location => "none" }
      format.json { render :json => @permissions.to_json, :location => "none" }
    end
  end

  # GET /users/<uid>/permissions/<id>
  # GET /users/<uid>/permissions/<id>.xml
  # GET /users/<uid>/permissions/<id>.json

  def show
    permission = Permission.new 	
    if permission_check( "org.opensuse.yast.webservice.read-permissions")
       get_permission_list(params[:user_id])

       for i in 0..@permissions.size-1
          if @permissions[i].name == params[:id]
              permission = @permissions[i]
              break
          end
       end
    else
       permission.error_id = 1
       permission.error_string = "no permission"
    end

    respond_to do |format|
      format.html { render :xml => permission, :location => "none" } #return xml only
      format.xml  { render :xml => permission, :location => "none" }
      format.json { render :json => permission.to_json, :location => "none" }
    end
  end

  # PUT /users/<uid>/permissions/<id>
  # PUT /users/<uid>/permissions/<id>.xml
  # PUT /users/<uid>/permissions/<id>.json

  def update
    if ( params[:permission] &&
         params[:permission].empty? == false )
       permission = Permission.new(params[:permission][:name], params[:permission][:grant] )
    elsif (params[:users] &&
           params[:users].empty? == false )
       permission = Permission.new(params[:users][:name], params[:users][:grant] )
    else
       permission = Permission.new
    end
    if permission_check( "org.opensuse.yast.webservice.read-permissions")
       permission.error_id = 0
       permission.error_string = ""     
       ret = Scr.execute(["polkit-auth", "--user", params[:user_id], permission.grant ? "--grant" : "--revoke", "org.opensuse.yast.webservice.#{params[:id]}"])
       if ret[:exit] != 0
          permission.error_id = 2
          permission.error_string = ret[:stderr]
          if permission.error_string.empty?
            permission.error_string = "user not found"
          end
       end
    else
       permission.error_id = 1
       permission.error_string = "no permission"
    end

    @permissions = []
    @permissions << permission

    respond_to do |format|
      format.html { render :xml => @permissions, :location => "none" } #return xml only
      format.xml  { render :xml => @permissions, :location => "none" }
      format.json { render :json => @permissions.to_json, :location => "none" }
    end
  end

end
