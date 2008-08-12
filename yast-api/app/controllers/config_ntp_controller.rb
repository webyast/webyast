include ApplicationHelper

class ConfigNtpController < ApplicationController
  def index

    @ntp = ConfigNtp.new
    @ntp.manual_server = ""
    @ntp.use_random_server = true

    ret = SCRExecute(".target.bash_output", "/sbin/yast2  ntp-client list")
    servers = ret[:stderr].split "\n"
    servers::each do |s|
      column = s.split (" ")
      column::each do |l|
        if l=="Server"
          if column[1] != "0.pool.ntp.org" && column[1] != "1.pool.ntp.org" && column[1] != "2.pool.ntp.org"
            if @ntp.manual_server == "" 
	       # Thats one user defined ntp-server
               @ntp.manual_server = column[1]
            else
               #There are more than one user defined server --> do not use it
               @ntp.manual_server = "No single configured ntp server"
            end
          end
        end
      end
      if @ntp.manual_server == ""
        @ntp.use_random_server = true
      else
        @ntp.use_random_server = false
      end
    end

    ret = SCRExecute(".target.bash_output", "LANG=en.UTF-8 /sbin/yast2  ntp-client status")
    if ret[:stderr]=="NTP daemon is enabled.\n"
      @ntp.enabled = true
    else      
      @ntp.enabled = true
    end

    respond_to do |format|
      format.xml do
        render :xml => @ntp.to_xml( :root => "ntp",
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

  def show
    index
  end

  def update
    respond_to do |format|
      ntp = ConfigNtp.new
      if ntp.update_attributes(params[:config_ntp])
        logger.debug "UPDATED: #{ntp.inspect}"

        #remove evtl.old server 
        ret = SCRExecute(".target.bash_output", "/sbin/yast2  ntp-client list")
        servers = ret[:stderr].split "\n"
        servers::each do |s|
          column = s.split " "
          column::each do |l|
            if l=="Server"
	      servers << column[1]
            end
          end
        end
       
        requestedServers = []
        if ntp.use_random_server = false
          requestedServers << ntp.manual_server
        else
          requestedServers = ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org"]
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
            SCRExecute(".target.bash_output",command)
          end
          requestedServers::each do |reqServer|
            command = "/sbin/yast2  ntp-client add #{reqServer}"
            SCRExecute(".target.bash_output",command)
          end
        end

	if ntp.enabled == true
          SCRExecute(".target.bash_output", "/sbin/yast2  ntp-client enable")
        else
          SCRExecute(".target.bash_output", "/sbin/yast2  ntp-client disable")
        end

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


end
