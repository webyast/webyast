require "scr"

include ApplicationHelper

class LanguageController < ApplicationController

   before_filter :login_required

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

#
# get
#


  def get_available
     ret = Scr.instance.execute(["/sbin/yast2", "language", "list"])
     @language.available = ret[:stderr]
  end

  def get_languages
     ret = Scr.instance.execute(["/sbin/yast2", "language", "summary"])
     lines = ret[:stderr].split "\n"
     lines.each do |s|    	
       column = s.split(" ")
       case column[0]
         when "Current"
           @language.first_language = column[2] 
         when "Additional"
           @language.second_languages = column[2] 
       end
     end
  end

#
# set
#

  def set_first_language (language)
    Scr.instance.execute(["/sbin/yast2", "language", "set",  "lang=#{language}", "no_packages"])
  end

  def set_second_languages (languages)
    Scr.instance.execute(["/sbin/yast2", "language", "set", "languages=#{languages}", "no_packages"])
  end



#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
	
  def update
    unless permission_check( "org.opensuse.yast.system.language.write")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @language = Language.new
    if params[:language] != nil 
       second_languages = []
       first_language = params[:language][:first_language]
       params[:language][:second_languages].each do |lang|
         second_languages << lang[:id]
       end
       logger.debug "UPDATED: #{first_language}, #{second_languages.inspect}"

       set_first_language first_language
       set_second_languages second_languages.join(",")

       @language.first_language = first_language
       @language.second_languages = second_languages
    else
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
    get_languages
    get_available

  end


end
