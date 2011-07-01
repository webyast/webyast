require "online_help.rb"

class OnlinehelpController < ApplicationController
  layout nil
   
  def show
    @help = OnlineHelp.find(params[:id])
    render :nothing=>true, :text=>@help and return
  end
end
