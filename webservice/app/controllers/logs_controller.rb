require 'scr'

class LogsController < ApplicationController

  def index
  end
  
  def show

    log_filename = case params[:id]
      when "messages" then '/var/log/messages'
      when "apache_access" then '/var/log/apache2/access_log'
      when "apache_error" then '/var/log/apache2/error_log'
      when "custom"
         # if a custom log is requested, then
         # we evaluate a filename parameter
         params[:filename].blank? ? nil : params[:filename]
      else params[:id]
    end

    # not found
    if log_filename.nil? or not File.exist?(log_filename)
      render :nothing => true, :status => 404 and return
    end

    # how many lines to show
    lines = case params[:lines]
      when nil then 50
      else params[:lines].to_i 
    end
    
    output = Scr.instance.execute(['tail', '-n', "#{lines}", log_filename])

    respond_to do |format|
      format.text { render :xml => output[:stdout] }
    end
  end

end
