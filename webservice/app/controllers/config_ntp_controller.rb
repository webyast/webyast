include ApplicationHelper

class ConfigNtpController < ApplicationController
#
#local functions
#
   def manualServer

     manual_server = ""
     ret = scrExecute(".target.bash_output", "/sbin/yast2  ntp-client list")
     servers = ret[:stderr].split "\n"
     servers::each do |s|
       column = s.split (" ")
       column::each do |l|
         if l=="Server"
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

     ret = scrExecute(".target.bash_output", "LANG=en.UTF-8 /sbin/yast2  ntp-client status")
     if ret[:stderr]=="NTP daemon is enabled.\n"
       return true
     else      
       return false
     end
   end

   def writeNTPConf (requestedServers)
     #remove evtl.old server if requested
     ret = scrExecute(".target.bash_output", "/sbin/yast2  ntp-client list")
     servers = ret[:stderr].split "\n"
     servers::each do |s|
       column = s.split " "
       column::each do |l|
         if l=="Server"
	   servers << column[1]
         end
       end
     end

     updateRequired = false
     requestedServers::each do |reqServer|
       found = false
         servers::each do |server|
          if server=reqServer
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
         scrExecute(".target.bash_output",command)
       end
       requestedServers::each do |reqServer|
         command = "/sbin/yast2  ntp-client add #{reqServer}"
         scrExecute(".target.bash_output",command)
       end
     end
   end

   def enable (enabled)
     if enabled == true
       scrExecute(".target.bash_output", "/sbin/yast2  ntp-client enable")
     else
       scrExecute(".target.bash_output", "/sbin/yast2  ntp-client disable")
     end
   end

#
#actions
#

  def show

    @ntp = ConfigNtp.new
    @ntp.manual_server = ""
    @ntp.use_random_server = true
    @ntp.manual_server = manualServer
    @ntp.enabled = enabled

    if @ntp.manual_server == ""
      @ntp.use_random_server = true
    else
      @ntp.use_random_server = false
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
        render
      end
    end
  end

  def update
    respond_to do |format|
      ntp = ConfigNtp.new
      if ntp.update_attributes(params[:config_ntp])
        logger.debug "UPDATED: #{ntp.inspect}"
       
        requestedServers = []
        if ntp.use_random_server = false
          requestedServers << ntp.manual_server
        else
          requestedServers = ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]
        end
        writeNTPConf(requestedServers)

        enable(ntp.enabled) 

        format.html { redirect_to :action => "show" }
	format.json { head :ok }
	format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => ntp.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  def singleValue
    if request.get?
      # GET
      @ntp = ConfigNtp.new
      case params[:id]
        when "manual_server"
          @ntp.manualServer = manualServer
        when "use_random_server"
          if manualServer == ""
            @ntp.use_random_server = true
          else
            @ntp.use_random_server = false
          end
        when "enabled"
          @ntp.enabled = enabled
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
          render :file => "#{RAILS_ROOT}/app/views/config_ntp/show.html.erb"
        end
      end      
    else
      #PUT
      respond_to do |format|
      @ntp = ConfigNtp.new
      if @ntp.update_attributes(params[:config_ntp])
        logger.debug "UPDATED: #{@ntp.inspect}"
        ok = true
        case params[:id]
          when "manual_server"
            writeNTPConf ([@ntp.manualServer])
          when "use_random_server"
            if (@ntp.use_random_server == true)
              writeNTPConf(["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"])
            else
              logger.debug "use_random_server:false. You will have to setup a manual_server too."
            end
          when "enabled"
            enable(@ntp.enabled == true)
          else
            logger.error "Wrong ID: #{params[:id]}"
            ok = false
        end

        format.html { redirect_to :action => "show" }
        if ok
          format.json { head :ok }
          format.xml { head :ok }
        else
          format.json { head :error }
          format.xml { head :error }
        end
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ntp.errors,
          :status => :unprocessable_entity }
      end
    end
    end
  end

end
