
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
     if permission_check("org.opensuse.yast.services.read")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permission_check("org.opensuse.yast.services.write")
        link.write_permission = true
     else
        link.write_permission = false
     end
     if permission_check("org.opensuse.yast.services.execute-commands") ||
        permission_check("org.opensuse.yast.services.execute")
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
     if permission_check("org.opensuse.yast.systemtime.read")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permission_check("org.opensuse.yast.systemtime.write")
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
     if permission_check("org.opensuse.yast.language.read")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permission_check("org.opensuse.yast.language.write")
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
     if permission_check("org.opensuse.yast.users.read")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permission_check("org.opensuse.yast.users.write")
        link.write_permission = true
     else
        link.write_permission = false
     end
     link.execute_permission = false
     if permission_check("org.opensuse.yast.users.delete")
        link.delete_permission = true
     else
        link.delete_permission = false
     end
     if permission_check("org.opensuse.yast.users.new")
        link.new_permission = true
     else
        link.new_permission = false
     end
     link.install_permission = false
     @links << link

     link = Links.new
     link.path = "permissions"
     link.description = "Managing user permissions. Usage: users/<user>/permissions.xml"
     if permission_check("org.opensuse.yast.webservice.read-permissions")
        link.read_permission = true
     else
        link.read_permission = false
     end
     if permission_check("org.opensuse.yast.webservice.write-permissions")
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
     if permission_check("org.opensuse.yast.patch.read")
        link.read_permission = true
     else
        link.read_permission = false
     end
     link.write_permission = false
     link.execute_permission = false
     link.delete_permission = false
     link.new_permission = false
     if permission_check("org.opensuse.yast.patch.install")
        link.install_permission = true
     else
        link.install_permission = false
     end
     @links << link

     link = Links.new
     link.path = "security"
     link.description = "Security"
     if permission_check("org.opensuse.yast.system.securities.read")
        link.read_permission = true
     else
        link.read_permission = false
     end
     link.write_permission = false
     link.execute_permission = false
     link.delete_permission = false
     link.new_permission = false
     if permission_check("org.opensuse.yast.system.securities.write")
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

