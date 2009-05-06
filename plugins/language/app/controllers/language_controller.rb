include ApplicationHelper

class LanguageController < ApplicationController

   before_filter :login_required

   require "scr"

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

#
# get
#


  def get_available
     ret = Scr.execute(["/sbin/yast2", "language", "list"])
     @language.available = ret[:stderr]
  end

  def get_languages
     ret = Scr.execute(["/sbin/yast2", "language", "summary"])
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
    Scr.execute(["/sbin/yast2", "language", "set",  "lang=#{language}", "no_packages"])
  end

  def set_second_languages (languages)
    Scr.execute(["/sbin/yast2", "language", "set", "languages=#{languages}", "no_packages"])
  end



#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
	
  def update
    respond_to do |format|
      language = Language.new
      if permission_check( "org.opensuse.yast.system.language.write" )
         if params[:language] != nil 
           second_languages = []
           first_language = params[:language][:first_language]
           params[:language][:second_languages].each do |lang|
             second_languages << lang[:id]
           end
           logger.debug "UPDATED: #{first_language}, #{second_languages.inspect}"

           set_first_language first_language
           set_second_languages second_languages.join(",")
         else
           language.error_id = 2
           language.error_string = "format or internal error"
         end
      else #no permissions
         language.error_id = 1
         language.error_string = "no permission"
      end

      format.html do
        render :xml => language.to_xml( :dasherize => false), :location => "none" #return xml only
      end
      format.xml do
        render :xml => language.to_xml( :dasherize => false), :location => "none"
      end
      format.json do
	render :json => language.to_json, :location => "none"
      end
    end
  end

  def create
     update
  end

  def index
    @language = Language.new
    if permission_check( "org.opensuse.yast.system.language.read" )
       get_languages
       get_available
    else
       @language.error_id = 1
       @language.error_string = "no permission"
    end

    respond_to do |format|
      format.xml do
        render :xml => @language.to_xml( :dasherize => false), :location => "none"
      end
      format.json do
	render :json => @language.to_json, :location => "none"
      end
      format.html do
        render :xml => @language.to_xml( :dasherize => false), :location => "none" #return xml only
      end
    end
  end

  def show
    index
  end


end
