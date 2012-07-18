
class ErrorsController < ApplicationController
  def routing
    error = {:description => _("Error 404 - The page does not exist.")}

    respond_to do |format|
      format.html {render 'shared/404', :status => 404}
      format.xml  {render :xml => error.to_xml(:root => :error), :status => 404}
      format.json {render :json=> error.to_json, :status => 404}
    end
  end
end