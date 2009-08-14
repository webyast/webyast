# = Base system controller
# Provides access to language settings for authentificated users.
# Main goal is checking permissions.
class LanguageController < ApplicationController

  before_filter :login_required

   def show
     @basesystem = Basesystem.find
   end

   def update
     @basesystem = Basesystem.find
     @basesystem.current = params[:basesystem][:current]
     @basesystem.save
     render :index
   end

   def create
     update
   end

end
