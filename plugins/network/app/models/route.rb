# = Routing model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Routes

  # default route
  attr_accessor :default

  private

  public

  def initialize(kwargs)
    @default = kwargs["default"]
  end

  # fills route instance with data from YaPI.
  #
  # +warn+: Doesn't take any parameters.
  def Routes.find
    response = YastService.Call("YaPI::NETWORK::Read") # hostname: true
    ret = Routes.new(response["routes"])
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    settings = {
      "default" => @default,
    }
    YastService.Call("YaPI::NETWORK::Write",{"routes" => settings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.hostname do
      xml.default @default
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
