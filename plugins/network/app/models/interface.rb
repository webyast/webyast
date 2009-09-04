# = Hostname model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Interface

  # the short hostname
  attr_accessor :bootproto
  # the domain name
  attr_accessor :ipaddr

  private

  public

  def initialize(kwargs)
    @bootproto = kwargs["bootproto"]
    @ipaddr    = kwargs["ipaddr"]
  end

  # fills time instance with data from YaPI.
  #
  # +warn+: Doesn't take any parameters.
  def Interface.find(which)
    response = YastService.Call("YaPI::NETWORK::Read") # hostname: true
    ret = Interface.new(response["interfaces"][which])
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    settings = {
      "bootproto" => @bootproto,
      "ipaddr" => @ipaddr,
    }
    YastService.Call("YaPI::NETWORK::Write",{"interfaces" => settings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.interface do
      xml.bootproto @bootproto
      xml.ipaddr    @ipaddr
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
