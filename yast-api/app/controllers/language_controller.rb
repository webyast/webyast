include ApplicationHelper

class LanguageController < ApplicationController


#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

#
# get
#


  def get_languages
     ret = scrExecute(".target.bash_output", "LANG=en.UTF-8 /sbin/yast2 language summary")
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
    command = "/sbin/yast2  language set lang=#{language}"
    scrExecute(".target.bash_output",command)
  end

  def set_secondLanguages (languages)
    command = "/sbin/yast2  language set languages=#{languages}"
    scrExecute(".target.bash_output",command)
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
        format.xml  { render :xml => systemtime.errors,
          :status => :unprocessable_entity }
      end
    end
  end

  def index
    @language = Language.new
    get_languages

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
      get_languages
      @value = SingleValue.new
      @value.name = params[:id]
      case @value.name
        when "firstLanguage"
          @value.value = @language.firstLanguage
        when "secondLanguages"
          @value.value = @language.secondLanguages
      end
      respond_to do |format|
        format.xml do
          render :xml => @value.to_xml( :root => "single_value",
            :dasherize => false )
        end
        format.json do
	  render :json => @value.to_json
        end
        format.html do
          render :file => "#{RAILS_ROOT}/app/views/single_values/singleValue.html.erb"
        end
      end      
    else
      #PUT
      respond_to do |format|
        value = SingleValue.new
        if value.update_attributes(params[:single_value])
          logger.debug "UPDATED: #{value.inspect}"
          ok = true
          case value.name
            when "firstLanguage"
              set_firstLanguage value.value
            when "secondLanguages"
              set_secondLanguages value.value
            else
              logger.error "Wrong ID: #{value.name}"
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
          format.xml  { render :xml => value.errors,
            :status => :unprocessable_entity }
        end
      end
    end
  end




end
