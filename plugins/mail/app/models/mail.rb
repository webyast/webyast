require 'singleton'
require 'yast_service'

# = Mail model
# Proviceds access local mail settings (SMTP server to use)
# Uses YaPI::MailSettings for read and write operations,
# YaPI::SERVICES, for reloading postfix service.
class Mail

  attr_accessor :smtp_server
  attr_accessor :user
  attr_accessor :password
  attr_accessor :transport_layer_security

  include Singleton

  def initialize
  end

  # read the settings from system
  def read
    yapi_ret = YastService.Call("YaPI::MailSettings::Read")
    raise MailError.new("Cannot read from YaPI backend") if yapi_ret.nil?

    @smtp_server	= yapi_ret["smtp_server"]
    @user		= yapi_ret["user"]
    @password		= yapi_ret["password"]
    @transport_layer_security	= "no"
    @transport_layer_security	= yapi_ret["TLS"] if yapi_ret.has_key? "TLS"
  end


  # Save new mail settings
  def save(settings)

    # fill settings hash if it misses some keys
    ["transport_layer_security", "smtp_server", "user", "password"].each do |key|
	settings[key] = "" if (!settings.has_key? key) || settings[key].nil?
    end

    if settings["transport_layer_security"] == @transport_layer_security &&
       settings["smtp_server"] == @smtp_server &&
       settings["user"] == @user && settings["password"] == @password
      Rails.logger.debug "nothing has been changed, not saving"
      return true
    end

    parameters	= {
	"smtp_server"	=> [ "s", settings["smtp_server"]],
	"user"		=> [ "s", settings["user"]],
	"password"	=> [ "s", settings["password"]],
	"TLS"		=> [ "s", settings["transport_layer_security"]]
    }

    yapi_ret = YastService.Call("YaPI::MailSettings::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
    raise MailError.new(yapi_ret) unless yapi_ret.empty?
    true
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.mail do
      xml.smtp_server smtp_server
      xml.user user
      xml.password password
      xml.transport_layer_security transport_layer_security
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end

require 'exceptions'
class MailError < BackendException

  def initialize(message)
    @message = message
    super("Mail setup failed with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "MAIL_SETTINGS_ERROR"
      xml.description message
      xml.output @message
    end
  end
end
