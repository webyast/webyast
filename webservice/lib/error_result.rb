#
# Handle HTTP error result
#

class ErrorResult
  
  # return parameters for 'render'
  def self.error ( status = 400, code = 1, message = "Unspecific")
    Rails.logger.error "Error #{code}:#{message}"
    { :partial => "layouts/error", :status => status, :locals => { :code => code, :message => message } }
  end
  
end