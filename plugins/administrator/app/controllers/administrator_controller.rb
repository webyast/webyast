class AdministratorController < ApplicationController

  before_filter :login_required

  # GET action
  def show
    unless permission_check("org.opensuse.yast.modules.yapi.administrator.read")
      render ErrorResult.error(403, 1, "no permission for reading") and return
    end

    @admin = Administrator.instance
    @aliases	= @admin.read_aliases

    respond_to do |format|
      format.html { render :xml => @aliases.to_xml(:root => 'aliases'), :location => "none" } #return xml only
      format.xml  { render :xml => @aliases.to_xml(:root => 'aliases'), :location => "none" }
      format.json { render :json => @aliases.to_json, :location => "none" }
    end
  end
   
  # PUT action
  def update

    unless permission_check("org.opensuse.yast.modules.yapi.administrator.write")
      render ErrorResult.error(403, 1, "no permission for writing") and return
    end
	
    @admin = Administrator.instance

    if params.has_key?(:password) && !params[:password].empty?
      @admin.save_password(params[:password])
    end

    if params.has_key?(:aliases)
      @admin.save_aliases(params[:aliases])
    end

    show
  end

end
