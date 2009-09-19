# = Hostname model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Interface

  attr_accessor :bootproto,
  		:ipaddr,
		:id

  private

  public

  def initialize(kwargs, id=nil)
    @bootproto = kwargs["bootproto"]
    @ipaddr    = kwargs["ipaddr"] || ""
    @id	       = kwargs["id"] || id
  end

  def self.find( which )
    response = YastService.Call("YaPI::NETWORK::Read")
    ifaces_h = response["interfaces"]
    if which == :all
      ret = Hash.new
      ifaces_h.each do |id, ifaces_h|
        ret[id] = Interface.new(ifaces_h, id)
      end
    else
      ret = Interface.new(ifaces_h[which], which)
    end
    return ret
  end


  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    if @bootproto==""
      settings = {@id=>{}}
    else
      settings = {
        @id => {
	      "bootproto" => @bootproto,
	      "ipaddr" => @ipaddr
        }
      }
    end
    vsettings = [ "a{sa{ss}}", settings ] # bnc#538050
    YastService.Call("YaPI::NETWORK::Write",{"interface" => vsettings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.interface do
      xml.id	@id
      xml.bootproto @bootproto
      xml.ipaddr    @ipaddr
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
