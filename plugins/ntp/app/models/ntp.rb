class Ntp < BaseModel::Base

  attr_accessor :actions

  validates_inclusion_of :'actions[:synchronize]', :in => [ true, false ], :allow_nil => true

  before_save { yapi_perm_check "ntp.synchronize" if actions[:synchronize] }

  public
    def initialize(args={})
      @actions = { :synchronize => false }
      super args
    end
    
    def self.find
      Ntp.new
    end

    def save
      synchronize if @actions[:synchronize]
    end

  private
    def synchronize
      ret = "OK"
      begin
        ret = YastService.Call("YaPI::NTP::Synchronize")
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
