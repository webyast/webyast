# = Hostname model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class DNS

  # the short hostname
  attr_accessor :searches
  # the domain name
  attr_accessor :nameservers

  private

  public

  def initialize(kwargs)
    @searches = kwargs["searches"]
    @nameservers = kwargs["nameservers"]
  end

  # fills time instance with data from YaPI.
  #
  # +warn+: Doesn't take any parameters.
  def DNS.find
    response = YastService.Call("YaPI::NETWORK::Read") # hostname: true
    ret = DNS.new(response["dns"])
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def save
    settings = {
      "searches" => @searches,
      "nameservers" => @nameservers,
    }
    vsettings = [ "a{sas}", settings ] # bnc#538050    
    YastService.Call("YaPI::NETWORK::Write",{"dns" => vsettings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.dns do
      xml.nameservers({:type => "array"}) do
	  nameservers.each do |s|
	    xml.nameserver s
	  end
      end
      xml.searches({:type => "array"}) do
	searches.each do |s|
               xml.search s
         end
      end
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
