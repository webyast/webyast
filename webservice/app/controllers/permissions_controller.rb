class PermissionsController < ApplicationController

  before_filter :login_required

  require "scr"

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------


  def get_permission_list(user_id, filter = nil)
     @permissions = []
     if permission_check( "org.opensuse.yast.permissions.read")
       ret = Scr.execute(["polkit-action"])
       if ret[:exit] == 0
          suse_string = "org.opensuse.yast."
          lines = ret[:stdout].split "\n"
          lines.each do |s|   
             if (s.include?( suse_string )) &&
                (filter.blank? || s.include?( filter ))
                permission = Permission.new 	
                permission.name = s
                permission.grant = false
                permission.error_id = 0
                permission.error_string = ""
                @permissions << permission
             end
          end
          if user_id.blank?
             ret[:exit] = -1
          else
             ret = Scr.execute(["polkit-auth", "--user", user_id, "--explicit"])
          end
          if ret[:exit] == 0
             lines = ret[:stdout].split "\n"
             lines.each do |s|   
                   if s.include? suse_string
                   for i in 0..@permissions.size-1
                      if @permissions[i].name == s
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

  # GET /permissions?user_id=<user_id>&filter=<filter>
  # GET /permissions.xml?user_id=<user_id>&filter=<filter>
  # GET /permissions.json?user_id=<user_id>&filter=<filter>

  def index
    get_permission_list(params[:user_id], params[:filter])

    respond_to do |format|
      format.html { render :xml => @permissions, :location => "none" } #return xml only
      format.xml  { render :xml => @permissions, :location => "none" }
      format.json { render :json => @permissions.to_json, :location => "none" }
    end
  end

  # GET /users/<uid>/permissions/<id>?user_id=<user_id>
  # GET /users/<uid>/permissions/<id>.xml?user_id=<user_id>
  # GET /users/<uid>/permissions/<id>.json?user_id=<user_id>

  def show
    jsonFormat = false
    right = params[:id]
    if params[:id].end_with?(".json")
       jsonFormat = true
       right = params[:id].slice(0..-7)
    else
       right = params[:id].slice(0..-5) if params[:id].end_with?(".xml")
    end
    permission = Permission.new 	
    if permission_check( "org.opensuse.yast.permissions.read")
       get_permission_list(params[:user_id])

       for i in 0..@permissions.size-1
          if @permissions[i].name == right
              permission = @permissions[i]
              break
          end
       end
       if permission.name.blank?
          permission.name = right
          permission.error_id = 2
          permission.error_string = "permission not found"
       end
    else
       permission.error_id = 1
       permission.error_string = "no permission"
    end

    return render(:json => permission.to_json, :location => "none") if jsonFormat
    return render(:xml => permission, :location => "none")
  end

  # PUT /permissions?user_id=<user_id>
  # PUT /permissions/<id>.xml?user_id=<user_id>
  # PUT /permissions/<id>.json?user_id=<user_id>

  def update
    jsonFormat = false
    right = params[:id]
    if params[:id].end_with?(".json")
       jsonFormat = true
       right = params[:id].slice(0..-7)
    else
       right = params[:id].slice(0..-5) if params[:id].end_with?(".xml")
    end
    if ( not params[:permission].blank? )
       permission = Permission.new(right, params[:permission][:grant] )
    else
       permission = Permission.new
    end
    if permission_check( "org.opensuse.yast.permissions.write")
       permission.error_id = 0
       permission.error_string = ""     
       if params[:user_id].blank?
          ret[:exit] = -1
       else
          ret = Scr.execute(["polkit-auth", "--user", params[:user_id], permission.grant ? "--grant" : "--revoke", "org.opensuse.yast.webservice.#{params[:id]}"])
       end
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

    return render(:json => permission.to_json, :location => "none") if jsonFormat
    return render(:xml => permission, :location => "none")

  end

end
