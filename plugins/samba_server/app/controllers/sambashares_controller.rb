
require "samba_share"

class SambasharesController < ApplicationController

    before_filter :login_required

    # GET /sambashares
    # GET /sambashares.xml
    # GET /sambashares.json
    def index
	# read all Samba shares
	yapi_perm_check "samba.getalldirectories"

	@shares = SambaShare.find_all
    
	respond_to do |format|
	    format.xml  { render :xml => @shares, :location => "none" }
	    format.json { render :json => @shares.to_json, :location => "none" }
	end
    end

    # GET /sambashares/share_name
    # GET /sambashares/share_name.xml
    # GET /sambashares/share_name.json
    # return properties of a samba share, use YaPI::Samba Yast module
    def show
	yapi_perm_check "samba.getshare"

	@share = SambaShare.new
	@share.id = params[:id]

	if !@share.find
	    render ErrorResult.error(404, 2, "share not found") and return
	end

	respond_to do |format|
	    format.xml  { render :xml => @share, :location => "none" }
	    format.json { render :json => @share.to_json, :location => "none" }
	end
    end

    # POST /users
    # POST /users.xml
    # POST /users.json
    def create
	@share = SambaShare.new

	yapi_perm_check "samba.addshare"

	if !@share.update_attributes(params[:sambashares][:parameters], true)
	  render ErrorResult.error(404, 2, "input error") and return
	end

	if !@share.id.blank?
	  if !@share.add
	    render ErrorResult.error(404, 3, "adding share failed") and return
	  end
	else
	  render ErrorResult.error(404, 4, "empty share name") and return
	end

	respond_to do |format|
	    format.xml  { render :xml => @share, :location => "none" }
	    format.json { render :json => @share.to_json, :location => "none" }
	end
    end

    # PUT /sambashares/share
    # PUT /sambashares/share.xml
    # PUT /sambashares/share.json
    def update
	yapi_perm_check "samba.editshare"

	@share = SambaShare.new
	@share.id = params[:id]

	if !@share.find
	    render ErrorResult.error(404, 2, "share not found") and return
	end

	begin
	    if !@share.update_attributes(params[:sambashares][:parameters])
		render ErrorResult.error(404, 2, "input error") and return
	    end
	rescue Exception => e
	    render ErrorResult.error(404, 2, "input error") and return
	end

	if !@share.edit
	    render ErrorResult.error(404, 3, "editing share failed") and return
	end

	respond_to do |format|
	    format.xml  { render :xml => @share, :location => "none" }
	    format.json { render :json => @share.to_json, :location => "none" }
	end
    end

    # DELETE /sambashares/share
    # DELETE /sambashares/share.xml
    # DELETE /sambashares/share.json
    def destroy
	yapi_perm_check "samba.deleteshare"

	@share = SambaShare.new 	
	@share.id = params[:id]

	if !@share.delete
	    render ErrorResult.error(404, 2, "delete failed") and return
	end

	respond_to do |format|
	    format.xml  { render :xml => @share, :location => "none" }
	    format.json { render :json => @share.to_json, :location => "none" }
	end
    end

end

