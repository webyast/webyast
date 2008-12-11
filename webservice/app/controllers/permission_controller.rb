class PermissionController < ApplicationController

  before_filter :login_required

  def show
     right = "org.opensuse.yast.webservice." + params[:id]
     @cmdRet = Hash.new
     if polkit_check( right, self.current_account.login) == :yes
        @cmdRet["permission"] = "granted"
     else
        @cmdRet["permission"] = "denied"
     end
     respond_to do |format|
       format.xml do
	 render :xml => @cmdRet.to_xml
       end
       format.json do
         render :json => @cmdRet.to_json
       end
       format.html do
	 render :xml => @cmdRet.to_xml #return xml onl
       end
     end
  end

end
