require 'scr'
#require 'vendor_setting'
require 'yast/config_file'

class LogsController < ApplicationController
  CONFIG_FILE="/etc/YaST2/vendor/logs.yml"

  def initialize
    @cfg = case File.exists?(CONFIG_FILE)
    when true then YaST::ConfigFile.new("/etc/YaST2/vendor/logs.yml")
    else {}
    end
  end
    
  def index
    xml = Builder::XmlMarkup.new
    xml.instruct!

    xml.logs(:type => :array) do
      @cfg.each do |logid, logdata|
        xml.log do
          xml.id logid
          xml.path logdata["path"]
          xml.description logdata["description"]
        end
      end
    end
          
    respond_to do |format|
      format.xml { render :xml => xml.target! }
    end
  end
  
  def show

    # find the configured logs, use /var/log/messages
    # as default
    id = params[:id]
    if !@cfg.has_key?(id) or ! @cfg[id].has_key?('path')
      render :nothing => true, :status => 404 and return
    end
      
    log_filename = @cfg[id]['path']

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
