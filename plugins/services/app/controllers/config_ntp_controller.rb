include ApplicationHelper

class ConfigNtpController < ApplicationController
  before_filter :login_required

  require "scr"
#
#local functions
#
   def get_manual_server

     manual_server = ""
     ret = Scr.execute(["/sbin/yast2",  "ntp-client",  "list"])
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
     return manual_server
   end

   def enabled

     ret = Scr.execute(["/sbin/yast2", "ntp-client", "status"])
     if ret[:stderr]=="NTP daemon is enabled.\n"
       return true
     else      
       return false
     end
   end

   def write_ntp_conf (requested_servers)
     update_required = false
     #remove evtl.old server if requested
     servers = []
     ret = Scr.execute(["/sbin/yast2", "ntp-client", "list"])
     servers_line = ret[:stderr].split "\n"
     servers_line.each do |s|
       column = s.split " "
       if column.size == 2 && column[0] == "Server"
	  servers << column[1]
       end
     end
     update_required = false
     requested_servers.each do |req_server|
       found = false
       servers.each do |server|
          if server==req_server
             found = true
          end
       end
       if !found
          update_required = true
       end
     end

     #update required
     if update_required
       servers.each do |server|
         Scr.execute(["/sbin/yast2", "ntp-client", "delete", server])
       end
       requested_servers.each do |req_server|
         Scr.execute(["/sbin/yast2", "ntp-client", "add", req_server])
       end
     end
   end

   def enable (enabled)
     if enabled == true
       Scr.execute(["/sbin/yast2", "ntp-client", "enable"])
     else
       Scr.execute(["/sbin/yast2", "ntp-client", "disable"])
     end
   end

#
#actions
#

  def show

    @ntp = ConfigNtp.new

    if ( permission_check( "org.opensuse.yast.webservice.read-services") or
         permission_check( "org.opensuse.yast.webservice.read-services-config") or
         permission_check( "org.opensuse.yast.webservice.read-services-config-ntp"))
       @ntp.manual_server = ""
       @ntp.use_random_server = true
       @ntp.manual_server = get_manual_server
       @ntp.enabled = enabled
       if @ntp.manual_server == ""
         @ntp.use_random_server = true
       else
         @ntp.use_random_server = false
       end
    else
       @ntp.error_id = 1
       @ntp.error_string = "no permission"
    end

    respond_to do |format|
      format.xml do
        render :xml => @ntp.to_xml( :root => "config_ntp",
          :dasherize => false )
      end
      format.json do
	render :json => @ntp.to_json
      end
      format.html do
        render :xml => @ntp.to_xml( :root => "config_ntp",
          :dasherize => false ) #return xml only
      end
    end
  end

  def update
    respond_to do |format|
      ntp = ConfigNtp.new
      if ( permission_check( "org.opensuse.yast.webservice.write-services") or
           permission_check( "org.opensuse.yast.webservice.write-services-config") or
           permission_check( "org.opensuse.yast.webservice.write-services-config-ntp"))
         if params[:config_ntp] != nil
            ntp.use_random_server = params[:config_ntp][:use_random_server]
            ntp.enabled = params[:config_ntp][:enabled]
            ntp.manual_server = params[:config_ntp][:manual_server]
            logger.debug "UPDATED: #{ntp.inspect}"
       
            requested_servers = []
            if ntp.use_random_server == false
              requested_servers << ntp.manual_server
            else
              requested_servers = ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]
            end
            write_ntp_conf(requested_servers)
            enable(ntp.enabled) 
         else
           ntp.error_id = 2
           ntp.error_string = "format or internal error"
         end  
      else #no permissions
         ntp.error_id = 1
         ntp.error_string = "no permission"
      end

      format.html do
        render :xml => ntp.to_xml( :root => "config_ntp",
          :dasherize => false ) #return xml only
      end
      format.xml do
        render :xml => ntp.to_xml( :root => "config_ntp",
          :dasherize => false )
      end
      format.json do
	render :json => ntp.to_json
      end
    end
  end

  def singlevalue
    if request.get?
      # GET
      @ntp = ConfigNtp.new
      case params[:id]
        when "manual_server"
          if ( permission_check( "org.opensuse.yast.webservice.read-services") or
               permission_check( "org.opensuse.yast.webservice.read-services-config") or
               permission_check( "org.opensuse.yast.webservice.read-services-config-ntp") or
               permission_check( "org.opensuse.yast.webservice.read-services-config-ntp-manualserver"))
             @ntp.manual_server = get_manual_server
          else
             @ntp.error_id = 1
             @ntp.error_string = "no permission"
          end
        when "use_random_server"
          if ( permission_check( "org.opensuse.yast.webservice.read-services") or
               permission_check( "org.opensuse.yast.webservice.read-services-config") or
               permission_check( "org.opensuse.yast.webservice.read-services-config-ntp") or
               permission_check( "org.opensuse.yast.webservice.read-services-config-ntp-userandomserver"))
             if manual_server == ""
               @ntp.use_random_server = true
             else
               @ntp.use_random_server = false
             end
          else
             @ntp.error_id = 1
             @ntp.error_string = "no permission"
          end
        when "enabled"
          if ( permission_check( "org.opensuse.yast.webservice.read-services") or
               permission_check( "org.opensuse.yast.webservice.read-services-config") or
               permission_check( "org.opensuse.yast.webservice.read-services-config-ntp") or
               permission_check( "org.opensuse.yast.webservice.read-services-config-ntp-enabled"))
             @ntp.enabled = enabled
          else
             @ntp.error_id = 1
             @ntp.error_string = "no permission"
          end
      end
      respond_to do |format|
        format.xml do
          render :xml => @ntp.to_xml( :root => "config_ntp",
            :dasherize => false )
        end
        format.json do
	  render :json => @ntp.to_json
        end
        format.html do
          render :xml => @ntp.to_xml( :root => "config_ntp",
            :dasherize => false ) #return xml only
        end
      end      
    else
      #PUT
      respond_to do |format|
         @ntp = ConfigNtp.new
         if params[:config_ntp] != nil
            ntp.use_random_server = params[:config_ntp][:use_random_server]
            ntp.enabled = params[:config_ntp][:enabled]
            ntp.manual_server = params[:config_ntp][:manual_server]
            logger.debug "UPDATED: #{@ntp.inspect}"
            case params[:id]
              when "manual_server"
                 if ( permission_check( "org.opensuse.yast.webservice.write-services") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config-ntp") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config-ntp-manualserver"))
                    write_ntp_conf ([@ntp.manual_server])
                 else
                    @ntp.error_id = 1
                    @ntp.error_string = "no permission"
                 end
              when "use_random_server"
                 if ( permission_check( "org.opensuse.yast.webservice.write-services") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config-ntp") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config-ntp-userandomserver"))
                    if (@ntp.use_random_server == true)
                       write_ntp_conf(["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"])
                    else
                       logger.debug "use_random_server:false. You will have to setup a manual_server too."
                       @ntp.error_string = "use_random_server:false. You will have to setup a manual_server too."
                    end
                 else
                   @ntp.error_id = 1
                   @ntp.error_string = "no permission"
                 end
              when "enabled"
                 if ( permission_check( "org.opensuse.yast.webservice.write-services") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config-ntp") or
                      permission_check( "org.opensuse.yast.webservice.write-services-config-ntp-enabled"))
                   enable(@ntp.enabled == true)
                 else
                   @ntp.error_id = 1
                   @ntp.error_string = "no permission"
                 end
              else
                 logger.error "Wrong ID: #{params[:id]}"
                 @ntp.error_id = 2
                 @ntp.error_string = "Wrong ID: #{params[:id]}"
            end
         else
            @ntp.error_id = 2
            @ntp.error_string = "format or internal error"
         end

         format.html do
             render :xml => @ntp.to_xml( :root => "config_ntp",
                    :dasherize => false ) #return xml only
         end
         format.xml do
             render :xml => @ntp.to_xml( :root => "config_ntp",
                    :dasherize => false )
         end
         format.json do
            render :json => @ntp.to_json
         end
      end
    end
  end

end
