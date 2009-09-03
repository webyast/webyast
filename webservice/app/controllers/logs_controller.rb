require 'scr'

class LogsController < ApplicationController

  def index
  end
  
  def show

    log_filename = case params[:id]
      when "messages" then '/var/log/messages'
      when "apache_access" then '/var/log/apache2/access_log'
      when "apache_error" then '/var/log/apache2/error_log'
      else nil
    end

    # not found
    if log_filename.nil?
      render :nothing, :status => 404 and return
    end

    # how many lines to show
    lines = case params[:lines]
      when nil then 50
      else params[:lines].to_i 
    end
    
    output = Scr.instance.execute(['tail', '-n', "#{lines}", log_filename])

    respond_to do |format|
      format.xml { render :xml => settings.to_xml }
      format.json { render :json => VendorSetting }
    end
    
    #render :text => output[:stdout]
    render :xml => xm.target!
  end

end
