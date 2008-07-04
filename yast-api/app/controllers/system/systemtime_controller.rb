class System::SystemtimeController < ApplicationController
  require 'rexml/document'
  require 'system/systemtime'
	def update
		
		#system("date -s ", params[:systemtime][:time])
		respond_to do |format|
			format.html { render :text => params[:systemtime][:time]}
			#format.json { render :json => request.to_json }
			#format.xml { render :xml => request }
		end
  end

	# Workaround for put-problem
	def create
		logger.error ("TTTTEEEEEESSSSSSST", params[:systemtime][:time])	
	end

  def show
			@systemtime = System::Systemtime.new
			@systemtime.time = `LANG=US date +%r`
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
