require "scr"

class YastModulesController < ApplicationController
  require 'yastModule'
  private

  def init_modules
    @yastModules = Hash.new
    YastModule.all.each do |d|
      begin
         yastModule = YastModule.new d
         @yastModules[yastModule.id] = yastModule
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

  def run
    id = params[:id]
    init_modules
    @yastModule = @yastModules[id]
    @yastModule.commands #evaluate commands

    if request.post?
      #execute command
      cmdLine = "LANG=en.UTF-8 /sbin/yast2 #{params[:id]} #{params[:command]}"
      found = false
      @yastModule.commands.each do |cname,option|
        if cname == params["command"]
          found = true
          command = @yastModule.commands[cname]
          if command != nil
            command["options"].each do |name,option|
              if params[name.to_s] != nil
                if option["kind"] == "string"
                  cmdLine += " #{name}=\"#{params[name.to_s]}\""
                else
                  cmdLine += " #{name}=#{params[name.to_s]}"
                end
              end
            end
          end
          @cmdRet = Scr.execute(cmdLine)
          render :file => "#{RAILS_ROOT}/app/views/yast_modules/results.html.erb"
        end
      end
      if !found
        STDERR.puts "command #{params[:command]} not found"
      end
    else
      #edit options
      respond @yastModule
    end
  end
end
