class SystemController < ApplicationController
  def time
    if params[:id]
      if request.get?
        render :text => SystemTime.find( 1 ).send( params[:id] )
      elsif request.put?
        s = SystemTime.find( 1)
        s.send( params[:id]+'=', request.raw_post )
        s.save!
        render :text => params[:id]
      end
    else
      respond_to do |format|
        format.xml do
          render :xml => SystemTime.find( 1 ).to_xml
        end
        format.json do
          render :json => SystemTime.find( 1 ).to_json
        end
      end
    end
  end
end

