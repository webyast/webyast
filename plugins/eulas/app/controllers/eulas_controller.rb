# = Eula controller
# Serves licences and handles notices about acceptations.
# User does not need any permissions
class EulasController < ApplicationController

  before_filter :login_required
  before_filter :ensure_license, :only => [:show, :update]
  
  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Renders a list of all available licences. Some (but not all) licence attributes
  # are shown, especially whether the license was already accepted or not.
  def index
    @licenses = License.find_all
    respond_to do |format|
      format.xml { render :xml => @licenses.to_xml }
      format.json{ render :json=> @licenses.to_json}
    end
  end

  # Render detailed info about a particular licence. Not all translations are 
  # rendered, only the selected one or english by default.
  def show
    @license.load_text params[:lang] unless params[:lang].nil?
    logger.debug @license.inspect
    respond_to do |format|
      format.xml { render :xml => @license.to_xml }
      format.json{ render :json=> @license.to_json}
    end
  end
  
  # Save updated license data. The only changeable attribute is "accepted"
  def update
    raise InvalidParameters.new({:id => 'MISSING'}) if params[:id].nil?
    raise InvalidParameters.new({:eulas_accepted => 'INVALID'}) unless [true,false,"true","false"].include? params[:eulas][:accepted]
    @license = License.find params[:id]
    render ErrorResult.error(404, 1, "License not found") and return if @license.nil?
    @license.accepted = ([true,"true"].include? params[:eulas][:accepted]) ? true : false
    @license.save
    respond_to do |format|
      format.xml { render :xml => @license.to_xml }
      format.json{ render :json=> @license.to_json}
    end
  end

  private

  def ensure_license
    raise InvalidParameters.new({:id => 'MISSING'}) if params[:id].nil?
    @id      = params[:id].to_i
    @license = License.find @id
    render ErrorResult.error(404, 1, "License not found") and return if @license.nil?
  end

end
