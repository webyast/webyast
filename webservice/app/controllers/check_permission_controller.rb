class CheckPermissionController < ApplicationController

  before_filter :login_required

  def show
     right = "org.opensuse.yast." + params[:id]
     @cmd_ret = Hash.new
     if polkit_check( right, self.current_account.login) == :yes
        @cmd_ret["permission"] = "granted"
     else
        @cmd_ret["permission"] = "denied"
     end
     respond_to do |format|
       format.xml do
	 render :xml => @cmd_ret.to_xml
       end
       format.json do
         render :json => @cmd_ret.to_json
       end
       format.html do
	 render :xml => @cmd_ret.to_xml #return xml onl
       end
     end
  end

end
