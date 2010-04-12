
class RestdocController < ApplicationController

  layout 'main'

  def index
    @restdocs = Restdoc.find :all

    Rails.logger.debug "Found restdoc files: #{@restdocs.inspect}"

  end

end
