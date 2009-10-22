require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'mail_settings'

class MailSettingsTest < ActiveSupport::TestCase

  def setup    
    @model = MailSettings.instance
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({ })
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', 'postfix', 'restart').returns({ "stdout" => "", "exit" => 0, "stderr" => ""})
    @model.read
  end

  def test_read_notls
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"SendingMail" => {
	    "RelayHost"	=> {
		"Name"	=> "smtp.domain.com"
	    }
	}
    })
    ret = @model.read
    assert @model.transport_layer_security == "NONE"
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
    assert @model.smtp_server == "smtp.domain.com"
    assert @model.transport_layer_security == "MUST"
  end


  def test_save_no_change
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"SendingMail" => {
	    "TLS"	=> "MUST",
	    "RelayHost"	=> {
		"Name"	=> "smtp.domain.com"
	    }
	}
    })
    ret = @model.read
    ret = @model.save({
	"smtp_server"	=> "smtp.domain.com",
	"user"		=> "",
	"password"	=> "",
	"transport_layer_security"	=> "MUST"
    })
    assert ret
  end

  def test_save
    YastService.stubs(:Call).with('YaPI::MailSettings::Write', {
      "Changed" => [ "i", 1],
      "MaximumMailSize" => [ "i", 10485760],
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


  def test_save_failure
    YastService.stubs(:Call).with('YaPI::MailSettings::Write', {
      "Changed" => [ "i", 1],
      "MaximumMailSize" => [ "i", 10485760],
      "SendingMail" => ["a{sv}", {
	  "Type"	=> [ "s", "relayhost"],
	  "TLS"		=> [ "s", ""],
	  "RelayHost"	=> [ "a{sv}", {
	      "Name"	=> [ "s", "smtp.newdomain.com"],
	      "Auth"	=> [ "i", 0],
	      "Account"	=> [ "s", ""],
	      "Password"=> [ "s", ""]
	  }]
      }]
   
    }).returns("Unknown mail sending TLS type. Allowed values are: NONE | MAY | MUST | MUST_NOPEERMATCH")
    assert_raise MailSettingsError do
      @model.save({
	"smtp_server"	=> "smtp.newdomain.com",
	"user"		=> "",
	"password"	=> ""
      })
    end
  end

end
