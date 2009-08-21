# = Hostname model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Hostname

  # the short hostname
  attr_accessor :name
  # the domain name
  attr_accessor :domain

  private

  public

  def initialize(kwargs)
    @name = kwargs["name"]
    @domain = kwargs["domain"]
  end

  # fills time instance with data from YaPI.
  #
  # +warn+: Doesn't take any parameters.
  def Hostname.find
    response = YastService.Call("YaPI::Network::Read") # hostname: true
    ret = Hostname.new(response["hostname"])
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    settings = {
      "name" => @name,
      "domain" => @domain,
    }
    YastService.Call("YaPI::Network::Write",{"hostname" => settings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.hostname do
      xml.name @name
      xml.domain @domain
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
