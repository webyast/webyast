class Ntp < BaseModel::Base

  attr_accessor :actions

  validates_inclusion_of :'actions[:synchronize]', :in => [ true, false ], :allow_nil => true


  public
    
    def self.find
      ret = Ntp.new
      ret.actions ||= {}
      if YastService.Call("YaPI::NTP::Available")
        ret.actions[:synchronize] = false
        ret.actions[:synchronize_utc] = true
      end
      return ret
    end

    def save
      synchronize if @actions[:synchronize]
    end

  private
    def synchronize
      ret = "OK"
      begin
        ret = YastService.Call("YaPI::NTP::Synchronize",@actions[:synchronize_utc])
      rescue Exception => e
        Rails.logger.info "ntp synchronization cause probably timeout #{e.inspect}"
      end
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
