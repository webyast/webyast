
class RegistrationState
  def self.read()
    unless Register.new.is_registered?
      return { :level => "warning",
               :message_id => "MISSING_REGISTRATION",
               :short_description => "Registration is missing",
               :long_description => "Please register your system in order to get updates.",
               :confirmation_host => "client",
               :confirmation_link => "/registration",
               :confirmation_label => "register" }
     else
       return {}
     end
  end
end
