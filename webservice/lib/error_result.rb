#
# Handle HTTP error result
#

class ErrorResult
  
  def self.error ( status = 400, code = 1, message = "Unspecific")
    { :layout => "error", :status => status, :code => code, :message => message }
  end
  
end