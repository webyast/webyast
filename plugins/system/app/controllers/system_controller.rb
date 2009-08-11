
class SystemController < ApplicationController

    before_filter :login_required

    def show
   	@actions = System.instance.actions

	respond_to do |format|
	    format.html { render :xml => @actions.to_xml(:root => :actions), :location => "none" } #return xml only
	    format.xml  { render :xml => @actions.to_xml(:root => :actions), :location => "none" }
	    format.json { render :json => @actions.to_json, :location => "none" }
	end
    end
   
    def update
	root = params[:time]
	if root == nil
	  render ErrorResult.error(404, 2, "format or internal error") and return
	end
	
	@system = System.instance

	# do the action
	action = params.find { |k, v| v == true}

	if not action.blank?
	    case action
		when :reboot
		    @system.reboot
		when :shutdown
		    @system.shutdown
		else
		    render ErrorResult.error(404, 2, "format error") and return
	    end
	end

	render :show
    end

    # See update
    def create
	update
    end

end
