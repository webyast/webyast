include ApplicationHelper

class ConfigNtpController < ApplicationController
  before_filter :login_required

  require "scr"

  def initialize  
    @scr = Scr.instance
  end
#
#local functions
#
   def get_manual_server

     manual_server = ""
     ret = @scr.execute(["/sbin/yast2",  "ntp-client",  "list"])
     if ret
       servers = ret[:stderr].split "\n"
       servers.each do |s|
         column = s.split(" ")
         if column.size == 2 && column[0] == "Server"
           if column[1] != "0.pool.ntp.org" && column[1] != "1.pool.ntp.org" && column[1] != "2.pool.ntp.org"
             if manual_server == "" 
	       # Thats one user defined ntp-server
               manual_server = column[1]
             else
               #There are more than one user defined server --> do not use it
               manual_server = "No single configured ntp server"
             end
           end
         end
       end
     end
     return manual_server
   end

   def enabled

     ret = @scr.execute(["/sbin/yast2", "ntp-client", "status"])
     return (ret[:stderr]=="NTP daemon is enabled.\n") if ret
     return false
   end

   def write_ntp_conf (requested_servers)
     update_required = false
     #remove evtl.old server if requested
     servers = []
     ret = @scr.execute(["/sbin/yast2", "ntp-client", "list"])
     servers_line = ret[:stderr].split "\n"
     servers_line.each do |s|
       column = s.split " "
       if column.size == 2 && column[0] == "Server"
	  servers << column[1]
       end
     end
     update_required = true
     requested_servers.each do |req_server|
       servers.each do |server|
          if server==req_server
             update_required = false
	     break
          end
       end
     end

     #update required
     if update_required
       servers.each do |server|
         @scr.execute(["/sbin/yast2", "ntp-client", "delete", server])
       end
       requested_servers.each do |req_server|
         @scr.execute(["/sbin/yast2", "ntp-client", "add", req_server])
       end
     end
   end

   def enable (enabled)
     @scr.execute(["/sbin/yast2", "ntp-client", enabled ? "enable" : "disable" ])
   end

#
#actions
#

  def show
    unless permission_check( "org.opensuse.yast.system.services.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @ntp = ConfigNtp.new
    @ntp.manual_server = ""
    @ntp.use_random_server = true
    @ntp.manual_server = get_manual_server
    @ntp.enabled = enabled
    if @ntp.manual_server == ""
      @ntp.use_random_server = true
    else
      @ntp.use_random_server = false
    end
  end

  def update

    unless permission_check( "org.opensuse.yast.system.services.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    @ntp = ConfigNtp.new
    if params[:config_ntp] != nil
      @ntp.use_random_server = params[:config_ntp][:use_random_server]
      @ntp.enabled = params[:config_ntp][:enabled]
      @ntp.manual_server = params[:config_ntp][:manual_server]
      logger.debug "UPDATED: #{@ntp.inspect}"
       
      requested_servers = []
      if @ntp.use_random_server == false
        requested_servers << @ntp.manual_server
      else
        requested_servers = ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]
      end
      write_ntp_conf(requested_servers)
      enable(@ntp.enabled) 
    else
      render ErrorResult.error(404, 2, "format or internal error") and return
    end
    render :show

  end


end
