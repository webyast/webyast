# = Base system controller
# Provides access to queue for basic system setup.
# It is really quite thin layer.
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
