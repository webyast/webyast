# = Base system controller
# Provides access to queue for basic system setup.
# It is really quite thin layer.
class BasesystemController < ApplicationController

  before_filter :login_required

   def show
     basesystem = Basesystem.find
     logger.warn "No steps defined for Basesystem" if basesystem.steps.nil? or basesystem.steps.empty?
     logger.debug basesystem.inspect
     
     respond_to do |format|
      format.xml { render  :xml => basesystem.to_xml( :dasherize => false ) }
      format.json { render :json => basesystem.to_json( :dasherize => false ) }
     end
   end

   def update
     @basesystem = Basesystem.new params[:basesystem]     
     @basesystem.save
     show
   end

   def create
     update
   end

end
