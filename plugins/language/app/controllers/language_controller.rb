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
       second_languages = []
       first_language = params[:language][:first_language]
       if params[:language][:second_languages]
         params[:language][:second_languages].each do |lang|
           second_languages << lang[:id]
         end
       end
       logger.info "UPDATED: #{first_language}, #{second_languages.inspect}"

       if first_language.blank?
         logger.warn("blank first language")
         render ErrorResult.error(404, 2, "format or internal error") and return
       end
       @language.first_language = first_language
       @language.second_languages = second_languages

       @language.safe()

       
    else
       logger.warn("No argument language")
       render ErrorResult.error(404, 2, "format or internal error") and return
    end
    render :show
  end

  def create
     update
  end


  def show
    unless permission_check( "org.opensuse.yast.system.language.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @language = Language.new
    @language.read

  end


end
