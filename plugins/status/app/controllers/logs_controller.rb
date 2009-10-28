require 'scr'
#require 'vendor_setting'
require 'yast/config_file'

class LogsController < ApplicationController
  CONFIG_FILE=File.join(Paths::CONFIG,"vendor","logs.yml")

  def initialize
    @cfg = YaST::ConfigFile.new(CONFIG_FILE)
  end
    
#XXX xml response should go to separate model, not to controller
  def index
    xml = Builder::XmlMarkup.new
    xml.instruct!

    xml.logs(:type => :array) do
      begin
        @cfg.each do |logid, logdata|
          xml.log do
            xml.id logid
            xml.path logdata["path"]
            xml.description logdata["description"]
          end
        end
      rescue YaST::ConfigFile::NotFoundError => error
        logger.error "config file #{CONFIG_FILE} not found"
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
    lines = params[:lines] ? params[:lines].to_i : 50
    
    output = Scr.instance.execute(['tail', '-n', "#{lines}", log_filename])
    
    respond_to do |format|
      format.text { render :xml => output[:stdout] }
    end
  end

end
