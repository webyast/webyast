# = Routing model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Route

  # default gateway
  attr_accessor :via,
		:id

  private

  public

  def initialize(kwargs, id = nil)
    @via = kwargs["via"]
    @id = kwargs["id"] || id
  end

  # fills route instance with data from YaPI.
  #
  # +warn+: YaPI implements default only.
  def self.find( which )
    response = YastService.Call("YaPI::NETWORK::Read")
    routes_h = response["routes"]
    if which == :all
      ret = Hash.new
      routes_h.each do |id, route_h|
        ret[id] = Route.new(route_h, id)
      end
    else
      ret = Route.new(routes_h[which], which)
    end
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    @via="" if @via==nil
    settings = {
      @id => { 'via'=>@via },
    }
    vsettings = [ "a{sa{ss}}", settings ] # bnc#538050
    ret = YastService.Call("YaPI::NETWORK::Write",{"route" => vsettings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.route do
      xml.id @id
      xml.via @via
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
