include ApplicationHelper

class ConfigNtpController < ApplicationController
  def index

    @ntp = ConfigNtp.new
    servers = []
    @ntp.manual_server = ""
    @ntp.use_random_server = true

    ret = SCRExecute(".target.bash_output", "/sbin/yast2  ntp-client list")
    servers = ret[:stderr].split "\n"
    servers::each do |s|
      column = s.split (" ")
      column::each do |l|
        if l=="Server"
          if @ntp.manual_server == "" && l != "0.pool.ntporg" && l != "1.pool.ntp.org" && l != "2.pool.ntp.org"
	     # Thats one user defined ntp-server
             @ntp.manual_server = column[1]
          else
             #There are more than one user defined server --> do not use it
             @ntp.manual_server = "There are more than one user defined ntp servers. Please check it."
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

  def update
    respond_to do |format|
      ntp = ConfigNtp.new
      if ntp.update_attributes(params[:config_ntp])
        logger.debug "UPDATED: #{ntp.inspect}"

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
