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
     @language.available = ret[:stderr].split "\n"
  end

  def get_languages
     ret = Scr.execute("LANG=en.UTF-8 /sbin/yast2 language summary")
     lines = ret[:stderr].split "\n"
     lines::each do |s|    	
       column = s.split (" ")
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
      if language.update_attributes(params[:language])
        logger.debug "UPDATED: #{language.inspect}"

        set_firstLanguage language.firstLanguage
        set_secondLanguages language.secondLanguages

        format.html { redirect_to :action => "show" }
	format.json { head :ok }
	format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => language.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  def index
    @language = Language.new
    get_languages
    get_available

    respond_to do |format|
      format.xml do
        render :xml => @language.to_xml( :root => "language",
          :dasherize => false )
      end
      format.json do
	render :json => @language.to_json
      end
      format.html do
        render 
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
          get_languages
          @language.secondLanguages=nil
        when "secondLanguages"
          get_languages  
          @language.firstLanguage=nil
        when "available"
          get_available
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
          render :file => "#{RAILS_ROOT}/app/views/language/index.html.erb"
        end
      end      
    else
      #PUT
      respond_to do |format|
        @language = Language.new
        if @language.update_attributes(params[:language])
          logger.debug "UPDATED: #{@language.inspect}"
          ok = true
          case params[:id]
            when "firstLanguage"
              set_firstLanguage @language.firstLanguage
            when "secondLanguages"
              set_secondLanguages @language.secondLanguages
            else
              logger.error "Wrong ID: #{params[:id]}"
              ok = false
          end

          format.html { redirect_to :action => "show" }
          if ok
            format.json { head :ok }
            format.xml { head :ok }
          else
            format.json { head :error }
            format.xml { head :error }
          end
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @language.errors,
            :status => :unprocessable_entity }
        end
      end
    end
  end


end
