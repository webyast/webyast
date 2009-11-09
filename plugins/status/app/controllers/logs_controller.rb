require 'yast/config_file'
require 'yast_service'

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
#FIXME report IT!!!
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
      #FIXME better report problem, look eg on permission module how it should be implemented
      render :nothing => true, :status => 404 and return
    end
      
    # how many lines to show
    lines = params[:lines] ? params[:lines].to_i : 50

    # call YaST ruby module directly: FIXME does not work...
    output = YastService.Call("LogFile::Read", ["s",id], ["s",lines.to_s])
    if output=="___WEBYAST___INVALID"
      logger.error "invalid id "+id #TODO some exception and better log it as it could be hack attempt
    end
    logger.info output
    respond_to do |format|
      format.xml { render :xml => "<log>#{output}</log>" }
      format.json { render :json => { :log => output }.to_json }
    end
  end

end
