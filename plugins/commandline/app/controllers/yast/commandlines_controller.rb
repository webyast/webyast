
class Yast::CommandlinesController < ApplicationController

  before_filter :login_required

  require 'commandline'

  ################################
  private

  def init_modules (check_policy)
    return unless (!check_policy or permission_check( "org.opensuse.yast.commandline.read"))
    @yast_modules = Hash.new
    Commandline.all.each do |d|
      begin
	yast_module = Commandline.new d
	@yast_modules[yast_module.id] = yast_module
      rescue # Don't fail on non-existing service. Should be more specific.
      end
    end
  end

  ################################
  public

  def index
    init_modules true #check policy
    if @yast_modules.nil?
      render ErrorResult.error(403, 1, "no permission") and return
    end
  end

  def show
    unless permission_check( "org.opensuse.yast.commandline.read") 
      render ErrorResult.error(403, 1, "no permission") and return
    end
      
    id = params[:id]
    init_modules false #check no policy
    @yast_module = @yast_modules[id]
    @yast_module.commands #evaluate commands
  end

  # Hide running a command behind HTTP POST (aka create)
  def create
    unless permission_check( "org.opensuse.yast.commandline.execute")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    id = params[:id]
    @cmd_ret = Hash.new
    init_modules false #check no policy
    @yast_module = @yast_modules[id]
    @yast_module.commands #evaluate commands


    if params["hash"] != nil
      #checking if the command is hosted in a own Hash
      params["hash"].each do |name,value|
	params[name] = value
      end
    end
    
    cmd = ["/sbin/yast2", params[:id], params[:command]]
    found = false
    @yast_module.commands.each do |cname,option|
      if cname == params["command"]
	found = true
	command = @yast_module.commands[cname]
	if command != nil
	  command["options"].each do |name,option|
	    if params[name.to_s] != nil
	      if option["type"] == "string" 
		if !params[name.to_s].empty? 
		  cmd << "#{name}=\"#{params[name.to_s]}\""
		end
	      else 
		if option["type"] == nil
		  cmd << name
		else
		  cmd << "#{name}=#{params[name.to_s]}"
		end
	      end
	    end
	  end
	end
	require "scr"
	@cmd_ret = Scr.instance.execute(cmd)
      end
    end
    if !found
      render ErrorResult.error(404, 2, "command #{params[:command]} not found") and return
    end
  end
end
