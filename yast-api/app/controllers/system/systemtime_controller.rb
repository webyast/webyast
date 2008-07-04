class System::SystemtimeController < ApplicationController
  require 'system/systemtime'
	def update
    #systemtime = System::Systemtime.new(params[:system])
		#system ("date -s", @systemtime.systemtime)
		#xmldoc = REXML::Document.new(request)
		#systemtime = ActiveResource::Base.find(params[:systemtime])
		#element = xmldoc.root
		#system ("date -s", request.raw_post )
		respond_to do |format|
      format.html { redirect_to :action => "show" }
			format.json { head :ok }
			format.xml { head :ok }
		end
  end

  def show
			@systemtime = System::Systemtime.new
			@systemtime.id = "systemtime"
			@systemtime.time = `date +%r`
			temp = `date +%Z`
			if temp == "UTC" then
				@systemtime.isUTC = true
			else
				@systemtime.isUTC = false
			end
			@systemtime.timezone = `date +%Z`

			respond_to do |format|
				format.xml do
					render :xml => @systemtime.to_xml
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
