class AdministratorController < ApplicationController

  before_filter :login_required

  # GET action
  def show
#    @aliases = Administrator.instance.aliases
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
