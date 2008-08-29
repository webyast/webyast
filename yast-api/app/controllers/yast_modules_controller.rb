class YastModulesController < ApplicationController
  require 'yastModule'
  private

  def init_modules
    @yastModules = Hash.new
    YastModule.all.each do |d|
      begin
         yastModule = YastModule.new d
         @yastModules[yastModule.link] = yastModule
      rescue # Don't fail on non-existing service. Should be more specific.
      end
    end
  end

  def respond data
    STDERR.puts "Respond #{data.class}"
    if data
      respond_to do |format|
	format.xml do
	  render :xml => data.to_xml
	end
	format.json do
	  render :json => data.to_json
	end
	format.html do
	  render
	end
      end
    else
      render :nothing => true, :status => 404 unless @service # not found
    end
  end
  public

  def index
    init_modules
    respond @yastModules
  end

  def show
    id = params[:id]
    init_modules
    @yastModule = @yastModules[id]
    YastModule.getcommands @yastModule.link #evaluate commands
    STDERR.puts "show@yastModules #{@yastModule.inspect}"
    respond @yastModule
  end
end
