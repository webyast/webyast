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
     ret = Scr.execute("LANG=en.UTF-8 /sbin/yast2 language list")
     @language.available = ret[:stderr]
  end

  def get_languages
     ret = Scr.execute("LANG=en.UTF-8 /sbin/yast2 language summary")
     lines = ret[:stderr].split "\n"
     lines::each do |s|    	
       column = s.split(" ")
       case column[0]
         when "Current"
           @language.firstLanguage = column[2] 
         when "Additional"
           @language.secondLanguages = column[2] 
       end
     end
  end

#
# set
#

  def set_firstLanguage (language)
    command = "/sbin/yast2  language set lang=#{language} no_packages"
    Scr.execute(command)
  end

  def set_secondLanguages (languages)
    command = "/sbin/yast2  language set languages=#{languages} no_packages"
    Scr.execute(command)
  end



#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------
	
  def update
    respond_to do |format|
      language = Language.new
      if permissionCheck( "org.opensuse.yast.webservice.write-language" )
         if language.update_attributes(params[:language])
           logger.debug "UPDATED: #{language.inspect}"

           set_firstLanguage language.firstLanguage
           set_secondLanguages language.secondLanguages
         else
           language.error_id = 2
           language.error_string = "format or internal error"
         end
      else #no permissions
         language.error_id = 1
         language.error_string = "no permission"
      end

      format.html do
        render :xml => language.to_xml( :root => "language",
          :dasherize => false), :location => "none" #return xml only
      end
      format.xml do
        render :xml => language.to_xml( :root => "language",
          :dasherize => false), :location => "none"
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
    if permissionCheck( "org.opensuse.yast.webservice.read-language" )
       get_languages
       get_available
    else
       @language.error_id = 1
       @language.error_string = "no permission"
    end

    respond_to do |format|
      format.xml do
        render :xml => @language.to_xml( :root => "language",
          :dasherize => false), :location => "none"
      end
      format.json do
	render :json => @language.to_json, :location => "none"
      end
      format.html do
        render :xml => @language.to_xml( :root => "language",
          :dasherize => false), :location => "none" #return xml only
      end
    end
  end

  def show
    index
  end

  def singleValue
    if request.get?
      # GET
      @language = Language.new
      
      #initialize not needed stuff (perhaps no permissions available)
      case params[:id]
        when "firstLanguage"
          if ( permissionCheck( "org.opensuse.yast.webservice.read-language" ) or
               permissionCheck( "org.opensuse.yast.webservice.read-language-firstlanguage" )) then
             get_languages
             @language.secondLanguages=nil
          else
             @language.error_id = 1
             @language.error_string = "no permission"
          end
        when "secondLanguages"
          if ( permissionCheck( "org.opensuse.yast.webservice.read-language" ) or
               permissionCheck( "org.opensuse.yast.webservice.read-language-secondlanguages" )) then
             get_languages  
             @language.firstLanguage=nil
          else
             @language.error_id = 1
             @language.error_string = "no permission"
          end
        when "available"
          if ( permissionCheck( "org.opensuse.yast.webservice.read-language" ) or
               permissionCheck( "org.opensuse.yast.webservice.read-language-available" )) then
             get_available
          else
             @language.error_id = 1
             @language.error_string = "no permission"
          end
      end

      respond_to do |format|
        format.xml do
          render :xml => @language.to_xml( :root => "language",
            :dasherize => false )
        end
        format.json do
	  render :json => @language.to_json
        end
        format.html do
          render :xml => @language.to_xml( :root => "language",
            :dasherize => false ) #return xml only
        end
      end      
    else
      #PUT
      respond_to do |format|
        @language = Language.new
        if @language.update_attributes(params[:language])
          logger.debug "UPDATED: #{@language.inspect}"
          case params[:id]
            when "firstLanguage"
              if ( permissionCheck( "org.opensuse.yast.webservice.write-language" ) or
                   permissionCheck( "org.opensuse.yast.webservice.write-language-firstlanguage" )) then
                 set_firstLanguage @language.firstLanguage
              else
                 @language.error_id = 1
                 @language.error_string = "no permission"
              end              
            when "secondLanguages"
              if ( permissionCheck( "org.opensuse.yast.webservice.write-language" ) or
                   permissionCheck( "org.opensuse.yast.webservice.write-language-secondlanguages" )) then
                 set_secondLanguages @language.secondLanguages
              else
                 @language.error_id = 1
                 @language.error_string = "no permission"
              end              
            else
              logger.error "Wrong ID: #{params[:id]}"
              @language.error_id = 2
              @language.error_string = "Wrong ID: #{params[:id]}"
          end
        else
           @language.error_id = 2
           @language.error_string = "format or internal error"
        end
        format.xml do
            render :xml => @language.to_xml( :root => "language",
                   :dasherize => false ) #return xml only
        end
        format.xml do
            render :xml => @language.to_xml( :root => "language",
                   :dasherize => false )
        end
        format.json do
           render :json => @language.to_json
        end
      end
    end
  end


end
