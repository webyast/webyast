include ApplicationHelper

class ConfigNtpController < ApplicationController
  before_filter :login_required

  require "scr"
#
#local functions
#
   def manualServer

     manual_server = ""
     ret = Scr.execute("/sbin/yast2  ntp-client list")
     servers = ret[:stderr].split "\n"
     servers::each do |s|
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

     ret = Scr.execute("LANG=en.UTF-8 /sbin/yast2  ntp-client status")
     if ret[:stderr]=="NTP daemon is enabled.\n"
       return true
     else      
       return false
     end
   end

   def writeNTPConf (requestedServers)
     #remove evtl.old server if requested
     servers = []
     ret = Scr.execute("/sbin/yast2  ntp-client list")
     serversLine = ret[:stderr].split "\n"
     serversLine::each do |s|
       column = s.split " "
       if column.size == 2 && column[0] == "Server"
	  servers << column[1]
       end
     end
     updateRequired = false
     requestedServers::each do |reqServer|
       found = false
       servers::each do |server|
          if server==reqServer
             found = true
          end
       end
       if !found
          updateRequired = true
       end
     end

     #update required
     if updateRequired
       servers::each do |server|
         command = "/sbin/yast2  ntp-client delete #{server}"
         Scr.execute(command)
       end
       requestedServers::each do |reqServer|
         command = "/sbin/yast2  ntp-client add #{reqServer}"
         Scr.execute(command)
       end
     end
   end

   def enable (enabled)
     if enabled == true
       Scr.execute("/sbin/yast2  ntp-client enable")
     else
       Scr.execute("/sbin/yast2  ntp-client disable")
     end
   end

#
#actions
#

  def show

    @ntp = ConfigNtp.new

    if ( permissionCheck( "org.opensuse.yast.webservice.read-services") or
         permissionCheck( "org.opensuse.yast.webservice.read-services-config") or
         permissionCheck( "org.opensuse.yast.webservice.read-services-config-ntp"))
       @ntp.manual_server = ""
       @ntp.use_random_server = true
       @ntp.manual_server = manualServer
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
      if ( permissionCheck( "org.opensuse.yast.webservice.write-services") or
           permissionCheck( "org.opensuse.yast.webservice.write-services-config") or
           permissionCheck( "org.opensuse.yast.webservice.write-services-config-ntp"))
         if ntp.update_attributes(params[:config_ntp])
            logger.debug "UPDATED: #{ntp.inspect}"
       
            requestedServers = []
            if ntp.use_random_server == false
              requestedServers << ntp.manual_server
            else
              requestedServers = ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]
            end
            writeNTPConf(requestedServers)
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

  def singleValue
    if request.get?
      # GET
      @ntp = ConfigNtp.new
      case params[:id]
        when "manual_server"
          if ( permissionCheck( "org.opensuse.yast.webservice.read-services") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config-ntp") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config-ntp-manualserver"))
             @ntp.manualServer = manualServer
          else
             @ntp.error_id = 1
             @ntp.error_string = "no permission"
          end
        when "use_random_server"
          if ( permissionCheck( "org.opensuse.yast.webservice.read-services") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config-ntp") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config-ntp-userandomserver"))
             if manualServer == ""
               @ntp.use_random_server = true
             else
               @ntp.use_random_server = false
             end
          else
             @ntp.error_id = 1
             @ntp.error_string = "no permission"
          end
        when "enabled"
          if ( permissionCheck( "org.opensuse.yast.webservice.read-services") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config-ntp") or
               permissionCheck( "org.opensuse.yast.webservice.read-services-config-ntp-enabled"))
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
         if @ntp.update_attributes(params[:config_ntp])
            logger.debug "UPDATED: #{@ntp.inspect}"
            case params[:id]
              when "manual_server"
                 if ( permissionCheck( "org.opensuse.yast.webservice.write-services") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config-ntp") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config-ntp-manualserver"))
                    writeNTPConf ([@ntp.manualServer])
                 else
                    @ntp.error_id = 1
                    @ntp.error_string = "no permission"
                 end
              when "use_random_server"
                 if ( permissionCheck( "org.opensuse.yast.webservice.write-services") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config-ntp") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config-ntp-userandomserver"))
                    if (@ntp.use_random_server == true)
                       writeNTPConf(["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"])
                    else
                       logger.debug "use_random_server:false. You will have to setup a manual_server too."
                       @ntp.error_string = "use_random_server:false. You will have to setup a manual_server too."
                    end
                 else
                   @ntp.error_id = 1
                   @ntp.error_string = "no permission"
                 end
              when "enabled"
                 if ( permissionCheck( "org.opensuse.yast.webservice.write-services") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config-ntp") or
                      permissionCheck( "org.opensuse.yast.webservice.write-services-config-ntp-enabled"))
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
