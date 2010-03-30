
class MailState
  def self.read()
    if File.exist? Mail::TEST_MAIL_FILE
      f = File.new(Mail::TEST_MAIL_FILE, 'r')
      mail = f.gets.chomp
      mail = "" if mail.nil?
      f.close
      return { :level => "warning",
               :message_id => "MAIL_SENT",
               :short_description => "Mail configuration test not confirmed",
               :long_description => "During Mail configuration, test mail was sent to %s . Was the mail delivered to this address?<br> If so, confirm it by pressing the button. Otherwise, check your mail confiuration again, even the '/var/log/mail' file." % mail,
               :confirmation_host => "service",
               :confirmation_link => "/mail/state",
               :confirmation_label => "Test mail received" }
      # TODO what about passing :log_file => '/var/log/mail', so status page could show its content?
    else
      return {}
    end   
  end
end
