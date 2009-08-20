# = Base system controller
# Provides access to queue for basic system setup.
# It is really quite thin layer.
class BasesystemController < ApplicationController

  before_filter :login_required

   def show
     @basesystem = Basesystem.find
   end

   def update
     @basesystem = Basesystem.find
     @basesystem.finish
     @basesystem.save
     render :show
   end

   def create
     update
   end

end
