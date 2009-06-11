require "scr"

include ApplicationHelper

class LanguageController < ApplicationController

   before_filter :login_required


#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
public
  def update
    unless permission_check( "org.opensuse.yast.system.language.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @language = Language.new
    if params.has_key?(:language)
      #fill by one thing to allow update by one item e.g. via ajax
       if params[:language][:current]
         @language.language = params[:language][:current]
         logger.info("set language to #{@language.language}")
       end
       if params[:language][:utf8]
         @language.utf8 = params[:language][:utf8]=="true"
         logger.info("set utf8 to #{@language.utf8}")
       end
       if params[:language][:rootlocale]
         @language.rootlocale = params[:language][:rootlocale]
         logger.info("set rootlocale to #{@language.rootlocale}")
       end
    else
       logger.warn("No argument to update")
       render ErrorResult.error(404, 2, "format or internal error") and return
    end
    render :show
  end

  def create
     update
  end


  def show

    @language = Language.new

  end


end
