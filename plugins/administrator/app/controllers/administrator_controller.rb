class AdministratorController < ApplicationController

  before_filter :login_required

  # GET action
  def show

    unless permission_check("org.opensuse.yast.modules.yapi.administrator.read")
      render ErrorResult.error(403, 1, "no permission for reading") and return
    end

    @admin = Administrator.instance
    @admin.read_aliases

    respond_to do |format|
      format.html { render :xml => @admin.to_xml(:root => "administrator"), :location => "none" } #return xml only
      format.xml  { render :xml => @admin.to_xml(:root => "administrator", :indent=>2), :location => "none" }
      format.json { render :json => @admin.to_json, :location => "none" }
    end
  end
   
  # PUT action
  def update
    unless permission_check("org.opensuse.yast.modules.yapi.administrator.write")
      render ErrorResult.error(403, 1, "no permission for writing") and return
    end
	
    data = params["administrator"]
    @admin = Administrator.instance
    @admin.read_aliases

    if data.has_key?(:password) && !data[:password].nil? && !data[:password].empty?
      @admin.save_password(data[:password])
    end

    if data.has_key?(:aliases) && !data[:aliases].nil?
      @admin.save_aliases(data[:aliases])
    end
    show
  end

  def create
    update
  end

end
