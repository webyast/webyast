require 'test_helper'

require 'mail_settings'

class MailSettingsTest < ActiveSupport::TestCase

  def setup    
    @model = MailSettings.instance
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({ })
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', 'postfix', 'reload').returns({ "stdout" => "", "exit" => 0, "stderr" => ""})
    @model.read
  end

  def test_save
    YastService.stubs(:Call).with('YaPI::MailSettings::Write', {
      "Changed" => [ "i", 1],
      "SendingMail" => ["a{sv}", {
	  "Type"	=> [ "s", "relayhost"],
	  "TLS"		=> [ "s", "NONE"],
	  "RelayHost"	=> [ "a{sv}", {
	      "Name"	=> [ "s", "smtp.newdomain.com"],
	      "Auth"	=> [ "i", 0],
	      "Account"	=> [ "s", ""],
	      "Password"=> [ "s", ""]
	  }]
      }]
   
    }).returns("")
    ret = @model.save({
	"smtp_server"	=> "smtp.newdomain.com",
	"user"		=> "",
	"password"	=> "",
	"transport_layer_security"	=> "NONE"
    })
    assert ret
  end

  def test_read
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"SendingMail" => {
	    "TLS"	=> "MUST",
	    "RelayHost"	=> {
		"Name"	=> "smtp.domain.com"
	    }
	}
    })
    ret = @model.read
    assert ret
    assert @model.smtp_server == "smtp.domain.com"
    assert @model.transport_layer_security == "MUST"
  end


  def test_save_failure
    YastService.stubs(:Call).with('YaPI::MailSettings::Write', {
      "Changed" => [ "i", 1],
      "SendingMail" => ["a{sv}", {
	  "Type"	=> [ "s", "relayhost"],
	  "TLS"		=> [ "s", nil],
	  "RelayHost"	=> [ "a{sv}", {
	      "Name"	=> [ "s", "smtp.newdomain.com"],
	      "Auth"	=> [ "i", 0],
	      "Account"	=> [ "s", ""],
	      "Password"=> [ "s", ""]
	  }]
      }]
   
    }).returns("TLS cannot be empty")
    assert_raise MailSettingsError do
      @model.save({
	"smtp_server"	=> "smtp.newdomain.com",
	"user"		=> "",
	"password"	=> ""
      })
    end
  end

end
