require "online_help.rb"

class OnlinehelpController < ApplicationController
  layout nil
   
  def show
    @help = OnlineHelp.find(params[:id])
    render :text=>@help and return
  end
end
