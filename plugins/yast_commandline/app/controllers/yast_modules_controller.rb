require "scr"

class YastModulesController < ApplicationController

  before_filter :login_required

  require 'yastModule'
  private

  def init_modules (check_policy)
    @yast_modules = Hash.new
    if (!check_policy or
        permission_check( "org.opensuse.yast.commandline.read-yastmodulelist"))
       YastModule.all.each do |d|
         begin
            yast_module = YastModule.new d
            @yast_modules[yast_module.id] = yast_module
         rescue # Don't fail on non-existing service. Should be more specific.
         end
       end
    else
       yast_module = YastModule.new ""
       yast_module.error_id = 1
       yast_module.error_string = "no permission"
       @yast_modules[yast_module.id] = yast_module
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
	  render :xml => data.to_xml #return xml only
	end
      end
    else
      render :nothing => true, :status => 404 unless @yast_modules # not found
    end
  end
  public

  def index
    init_modules true #check policy
    respond @yast_modules
  end

  def show
    id = params[:id]
    id_policy = id.tr_s('_', '-')
    id_policy = id_policy.chomp
    id_policy = id_policy.downcase
    id_policy = "org.opensuse.yast.commandline.read-" + id_policy
    if (permission_check( "org.opensuse.yast.commandline.read") or
        permission_check( id_policy))
       init_modules false #check no policy
       @yast_module = @yast_modules[id]
       @yast_module.commands #evaluate commands
    else
       @yast_module = YastModule.new ""
       @yast_module.error_id = 1
       @yast_module.error_string = "no permission"
    end

    respond @yast_module
  end


  def run
    id = params[:id]
    @cmd_ret = Hash.new
    id_policy = id.tr_s('_', '-')
    id_policy = id_policy.chomp
    id_policy = id_policy.downcase
    id_policy_long = "org.opensuse.yast.commandline.execute-" + id_policy
    if (permission_check( "org.opensuse.yast.commandline.execute") or
        permission_check( id_policy_long))
       init_modules false #check no policy
       @yast_module = @yast_modules[id]
       @yast_module.commands #evaluate commands

       if request.post?
         #execute command

         if params["hash"] != nil
           #checking if the command is hosted in a own Hash
           params["hash"].each do |name,value|
              puts "Split hash #{name}:#{value}"
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
           STDERR.puts "command #{params[:command]} not found"
           @cmd_ret["exit"] = 2
           @cmd_ret["stderr"] = "command #{params[:command]} not found"
           @cmd_ret["stdout"] = ""
         end
       else
         # no POST request

         id_policy_long = "org.opensuse.yast.commandline.read-" + id_policy
         if (permission_check( "org.opensuse.yast.commandline.read") or
             permission_check( id_policy_long))
            respond @yast_module
            return
         else
            @cmd_ret[:exit] = 1
            @cmd_ret[:stderr] = "no permission"
            @cmd_ret[:stdout] = ""
         end
       end
    else #no right
       @cmd_ret[:exit] = 1
       @cmd_ret[:stderr] = "no permission"
       @cmd_ret[:stdout] = ""
    end

    respond_to do |format|
       format.xml do
          render :xml => @cmd_ret.to_xml
       end
       format.json do
          render :json => @cmd_ret.to_json
       end
       format.html do
          render :xml => @cmd_ret.to_xml #return xml only
       end
    end
  end
end
