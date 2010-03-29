
class MailState
  def self.read()
    if File.exist? Mail::TEST_MAIL_FILE
      return { :level => "warning",
               :message_id => "MAIL_SENT",
               :short_description => "Test mail status",
               :long_description => "Do you have received your test mail ?",
               :confirmation_host => "service",
               :confirmation_link => "/mail/state",
               :confirmation_label => "Received" }
    else
      return {}
    end   
  end
end
