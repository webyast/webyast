require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'mail'

class MailTest < ActiveSupport::TestCase

  def setup    
    @model = Mail.instance
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({ })
    @model.read
  end

  def test_read_notls
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"smtp_server" => "smtp.domain.com"
    })
    ret = @model.read
    assert @model.transport_layer_security == "no"
  end

  def test_read
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"smtp_server"	=> "smtp.domain.com",
	"TLS"		=> "must"
    })
    ret = @model.read
    assert @model.smtp_server == "smtp.domain.com"
    assert @model.transport_layer_security == "must"
  end


  def test_save_no_change
    YastService.stubs(:Call).with('YaPI::MailSettings::Read').returns({
	"smtp_server"	=> "smtp.domain.com",
	"TLS"		=> "must",
	"user"		=> "",
	"password"	=> ""
    })
    ret = @model.read
    ret = @model.save({
	"smtp_server"	=> "smtp.domain.com",
	"user"		=> "",
	"password"	=> "",
	"transport_layer_security"	=> "must"
    })
    assert ret
  end

  def test_save
    YastService.stubs(:Call).with('YaPI::MailSettings::Write', {
	"smtp_server"	=> [ "s", "smtp.newdomain.com"],
	"TLS"		=> [ "s", "no"],
	"user"		=> [ "s", ""],
	"password"	=> [ "s", ""]
    }).returns("")
    ret = @model.save({
	"smtp_server"	=> "smtp.newdomain.com",
	"user"		=> "",
	"password"	=> "",
	"transport_layer_security"	=> "no"
    })
    assert ret
  end


#  def test_save_failure
#  end

end
