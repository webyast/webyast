require 'exceptions'
# = Systemtime controller
# Provides access to time settings for authentificated users.
# Main goal is checking permissions.
class RolesController < ApplicationController

  before_filter :login_required

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Sets time settings. Requires write permissions for time YaPI.
  def update
		#TODO check if id exist
		Role.find(params[:id]).load(params).save
		show
  end

  def create
		Role.new.load(params["roles"]).save
		params[:id] = params["roles"]["name"]
		show
  end

	def delete
		#TODO check if id exist
		Role.delete params[:id]
		index
	end

  # Shows time settings. Requires read permission for time YaPI.
  def show
		role = Role.find params[:id]
		unless role
			#TODO raise exception
			raise InvalidParameters.new :id => "NONEXIST"
		end

    respond_to do |format|
      format.xml { render :xml => role.to_xml( :dasherize => false ) }
      format.json { render :json => role.to_json( :dasherize => false ) }
    end
  end

  def index
    #TODO check permissions
    roles = Role.find
    
    respond_to do |format|
      format.xml { render :xml => roles.to_xml( :dasherize => false ) }
      format.json { render :json => roles.to_json( :dasherize => false ) }
    end
  end

end
