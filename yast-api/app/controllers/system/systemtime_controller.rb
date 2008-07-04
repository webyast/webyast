class System::SystemtimeController < ApplicationController
	
  def update
    respond_to do |format|
      systemtime = System::SystemTime.new
      if systemtime.update_attributes(params[:system_time])
        logger.debug "UPDATED: #{systemtime.inspect}"
        #system("date -s ", params[:systemtime][:time])
        format.html { redirect_to :action => "show" }
	format.json { head :ok }
	format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => systemtime.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  # Workaround for put-problem
  def create
    logger.error("TTTTEEEEEESSSSSSST", params[:systemtime][:time])	
  end

  def show
    @systemtime = System::SystemTime.new
    @systemtime.id = "systemtime"
    @systemtime.systemtime = `date +%r`
    temp = `date +%Z`
    if temp == "UTC" then
      @systemtime.is_utc = true
    else
      @systemtime.is_utc = false
    end
    @systemtime.timezone = `date +%Z`.chomp

    respond_to do |format|
      format.xml do
        render :xml => @systemtime.to_xml( :root => "systemtime",
          :dasherize => false )
      end
      format.json do
	render :json => @systemtime.to_json
      end
      format.html do
        render
      end
    end
  end

end
