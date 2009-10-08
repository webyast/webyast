# = Eula controller
# Serves licences and handles notices about acceptations.
class EulasController < ApplicationController

  before_filter :login_required

  def index
    @licenses = License.find_all
     respond_to do |format|
       format.html
       format.xml { render :xml => @licenses.to_xml }
       format.json{ render :json=> @licenses.to_json}
     end
   end

  def show
    @id      = params[:id].to_i
    @license = License.find @id
    if not params[:lang].nil? then @license.load_text params[:lang] end
    logger.debug @license.inspect
    respond_to do |format|
      format.html
      format.xml { render :xml => @license.to_xml }
      format.json{ render :json=> @license.to_json}
    end
  end

  def update
    @license = License.find params[:id]
    @license.accept = params[:license][:accept]
    @license.save
    render :show
  end

end
