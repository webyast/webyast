class Ntp

  attr_accessor :actions

  public
    def initialize
      @actions = { :synchronize => false }
    end
    
    def self.find
      Ntp.new
    end

    def save
      if @actions[:synchronize]
        synchronize
      end
    end

  private
    def synchronize
      ret = YastService.Call("YaPI::NTP::Synchronize")
      raise NtpError.new(ret) unless ret == "OK"
    end
end

require 'exceptions'
class NtpError < BackendException
  def initialize(message)
    @message = message
    super("Ntp failed to synchronize with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "NTP_ERROR"
      xml.description message
      xml.output @message
    end
  end
end