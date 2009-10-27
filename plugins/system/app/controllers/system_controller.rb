
class SystemController < ApplicationController

    before_filter :login_required

    def show
   	@actions = System.instance.actions

	respond_to do |format|
	    format.xml  { render :xml => @actions.to_xml(:root => :actions), :location => "none" }
	    format.json { render :json => @actions.to_json, :location => "none" }
	end
    end
   
    def update
	root = params[:system]
	if root == nil || root == {} 
	  render ErrorResult.error(404, 2, "format error - missing actions") and return
	end
	
	@system = System.instance

	do_reboot = false
	do_shutdown = false

	# do the action
	root.each do |k, v|
	    if v.nil? or !v.respond_to?('has_key?') or !v.has_key? 'active'
		render ErrorResult.error(404, 2, "format error - missing requested status") and return
	    end

	    if v['active'] != true and v['active'] != false
		render ErrorResult.error(404, 2, "format error - non-boolean active parameter") and return
	    end

	    # unknown action requested
	    if !@system.actions.has_key? k.to_sym
		render ErrorResult.error(404, 2, "format error - unknown action requested") and return
	    end

	    case k
		when 'reboot'
		    permission_check( 'org.freedesktop.hal.power-management.reboot')

		    if v['active'] == true and @system.actions[k.to_sym][:active] == false
			do_reboot = true
		    end
		when 'shutdown'
		    permission_check( 'org.freedesktop.hal.power-management.shutdown')

		    if v['active'] == true and @system.actions[k.to_sym][:active] == false
			do_shutdown = true
		    end
		else
		    render ErrorResult.error(404, 2, "internal error - unknown action requested") and return
	    end
	end

	if do_reboot then @system.reboot end
	if do_shutdown then @system.shutdown end

	show
    end

    # See update
    def create
	update
    end

end
