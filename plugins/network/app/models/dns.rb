# = Hostname model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class DNS

  # the short hostname
  attr_accessor :domains
  # the domain name
  attr_accessor :servers

  private

  public

  def initialize(kwargs)
    @domains = kwargs["dnsdomains"]
    @servers = kwargs["dnsservers"]
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
      "domains" => @domains,
      "servers" => @servers,
    }
    YastService.Call("YaPI::NETWORK::Write",{"hostname" => settings})
    # TODO success or not?
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.dns do
      xml.nameservers({:type => "array"}) do
	  servers.each do |s|
	    xml.nameserver s
	  end
      end
      xml.searches({:type => "array"}) do
         domains.each do |s|
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
