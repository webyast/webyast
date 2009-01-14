
class YastController < ApplicationController
  def index
     @links = []

     link = Links.new 	
     link.path = "login"
     link.description = "Creating a YaST Webservice session"
     @links << link

     link = Links.new 	
     link.path = "logout"
     link.description = "Closing YaST Webservice session"
     @links << link

     link = Links.new 	
     link.path = "services"
     link.description = "Managing Linux services like samba, ntp,..."
     @links << link

     link = Links.new 	
     link.path = "systemtime"
     link.description = "Setting system time"
     @links << link

     link = Links.new 	
     link.path = "language"
     link.description = "Setting language"
     @links << link

     link = Links.new 	
     link.path = "users"
     link.description = "Managing local user"
     @links << link

     link = Links.new 	
     link.path = "patch_updates"
     link.description = "Updating System"
     @links << link

     respond_to do |format|
       format.html { render } 
       format.xml  { render :xml => @links, :location => "none" }
       format.json { render :json => @links.to_json, :location => "none" }
     end
  end

  def show
     index
  end

end

