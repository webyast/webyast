include ApplicationHelper

class LanguageController < ApplicationController

   before_filter :login_required


private
  def fill_language
    if permission_check("org.opensuse.yast.modules.yapi.language.getlanguages")
      @language.fill_available
    else
      logger.info "yast2 language list no permissions"
    end

    if permission_check("org.opensuse.yast.modules.yapi.language.getcurrentlanguage")
      @language.fill_language
    else
      logger.info "yast2 current language no permissions"
    end

    if permission_check("org.opensuse.yast.modules.yapi.language.isutf8")
      @language.fill_utf8
    else
      logger.info "yast2 utf8 no permissions"
    end

    if permission_check("org.opensuse.yast.modules.yapi.language.getrootlang")
      @language.fill_rootlocale
    else
      logger.info "yast2 root locale no permissions"
    end

  end

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
public
  def update

    @language = Language.new
    if params.has_key?(:language)
      #fill by one thing to allow update by one item e.g. via ajax
      if params[:language][:current] && params[:language][:current] != ""
         unless permission_check("org.opensuse.yast.modules.yapi.language.setcurrentlanguage")
           render ErrorResult.error(403, 1, "no permission") and return
         end
       end
       if params[:language][:utf8] && params[:language][:utf8] != ""
         unless permission_check("org.opensuse.yast.modules.yapi.language.setutf8")
           render ErrorResult.error(403, 1, "no permission") and return
         end
       end
       if params[:language][:rootlocale] && params[:language][:rootlocale] != ""
         unless permission_check("org.opensuse.yast.modules.yapi.language.setrootlocale")
           render ErrorResult.error(403, 1, "no permission") and return
         end
       end
      if params[:language][:current] && params[:language][:current] != ""
         @language.language = params[:language][:current]
         logger.info("set language to #{@language.language}")
       end
       if params[:language][:utf8] && params[:language][:utf8] != ""
         @language.utf8 = params[:language][:utf8]=="true"
         logger.info("set utf8 to #{@language.utf8}")
       end
       if params[:language][:rootlocale] && params[:language][:rootlocale] != ""
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
    fill_language

  end


end
