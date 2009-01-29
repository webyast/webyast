
class YastController < ApplicationController

  def index
     @links = []

     link = Links.new 	
     link.path = "login"
     link.description = "Creating a YaST Webservice session"
     link.read_permission = true
     link.write_permission = true
     link.execute_permission = true
     link.delete_permission = true
     link.new_permission = true
     link.install_permission = true
     @links << link

     link = Links.new 	
     link.path = "logout"
     link.description = "Closing YaST Webservice session"
     link.read_permission = true
     link.write_permission = true
     link.execute_permission = true
     link.delete_permission = true
     link.new_permission = true
     link.install_permission = true
     @links << link

     link = Links.new 	
     link.path = "services"
     link.description = "Managing Linux services like samba, ntp,..."
     if permissionCheck("org.opensuse.yast.webservice.read-services")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permissionCheck("org.opensuse.yast.webservice.write-services")
        link.write_permission = true
     else
        link.write_permission = false
     end
     if permissionCheck("org.opensuse.yast.webservice.execute-services-commands") ||
        permissionCheck("org.opensuse.yast.webservice.execute-services")
        link.execute_permission = true
     else
        link.execute_permission = false
     end
     link.delete_permission = false
     link.new_permission = false
     link.install_permission = false
     @links << link

     link = Links.new 	
     link.path = "systemtime"
     link.description = "Setting system time"
     if permissionCheck("org.opensuse.yast.webservice.read-systemtime")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permissionCheck("org.opensuse.yast.webservice.write-systemtime")
        link.write_permission = true
     else
        link.write_permission = false
     end
     link.execute_permission = false
     link.delete_permission = false
     link.new_permission = false
     link.install_permission = false
     @links << link

     link = Links.new 	
     link.path = "language"
     link.description = "Setting language"
     if permissionCheck("org.opensuse.yast.webservice.read-language")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permissionCheck("org.opensuse.yast.webservice.write-language")
        link.write_permission = true
     else
        link.write_permission = false
     end
     link.execute_permission = false
     link.delete_permission = false
     link.new_permission = false
     link.install_permission = false
     @links << link

     link = Links.new 	
     link.path = "users"
     link.description = "Managing local user"
     if permissionCheck("org.opensuse.yast.webservice.read-user")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permissionCheck("org.opensuse.yast.webservice.write-user")
        link.write_permission = true
     else
        link.write_permission = false
     end
     link.execute_permission = false
     if permissionCheck("org.opensuse.yast.webservice.delete-user")
        link.delete_permission = true
     else
        link.delete_permission = false
     end
     if permissionCheck("org.opensuse.yast.webservice.new-user")
        link.new_permission = true
     else
        link.new_permission = false
     end
     link.install_permission = false
     @links << link

     link = Links.new 	
     link.path = "permissions"
     link.description = "Managing user permissions. Usage: users/<user>/permissions.xml"
     if permissionCheck("org.opensuse.yast.webservice.read-permissions")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permissionCheck("org.opensuse.yast.webservice.write-permissions")
        link.write_permission = true
     else
        link.write_permission = false
     end
     link.execute_permission = false
     link.delete_permission = false
     link.new_permission = false
     link.install_permission = false
     @links << link

     link = Links.new 	
     link.path = "patch_updates"
     link.description = "Updating System"
     if permissionCheck("org.opensuse.yast.webservice.read-patch")
        link.read_permission = true
     else
        link.read_permission = false
     end
     link.write_permission = false
     link.execute_permission = false
     link.delete_permission = false
     link.new_permission = false
     if permissionCheck("org.opensuse.yast.webservice.install-patch")
        link.install_permission = true
     else
        link.install_permission = false
     end
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

