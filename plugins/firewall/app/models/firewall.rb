class Firewall < BaseModel::Base

  attr_accessor :use_firewall, :fw_services

  def self.find
    Firewall.new YastService.Call("YaPI::FIREWALL::Read")
  end

  def save
    result = {"saved_ok" => true}
    fw_save_data = {'use_firewall' => @use_firewall, 'fw_services' => @fw_services.collect {|h| h.delete "name"; h} }
    #begin
    result = YastService.Call("YaPI::FIREWALL::Write", Firewall.toVariantASV(fw_save_data) )
    #rescue Exception => e
    #  Rails.logger.info "firewall configuration saving error: #{e.inspect}"
    #  
    #end
    raise FirewallException.new(result["error"]) unless result["saved_ok"]
  end

  def self.toVariant(value)
    if    value.is_a? TrueClass
      ["b",true]
    elsif value.is_a? FalseClass
      ["b",false]
    elsif value.is_a? String
      ["s",value]
    elsif value.is_a? Fixnum
      ["i",value]
    elsif value.is_a? Float
      ["d",value]
    elsif value.is_a? Hash
      ["a{sv}", value.to_a.collect {|kv| [ (kv[0].to_s), toVariant(kv[1])] } ]
    elsif value.is_a? Array
      ["av", value.collect {|v| toVariant v}]
    else
      raise "Unknown variant type!"
    end
  end

  def self.toVariantASV(value)
    result = value.clone
    result.each {|k,v| result[k] = toVariant(v) }
    result
  end
end

require 'exceptions'

# Exception, which signalizes, that some functionality of backend was requested
# without accepting the EULA first.
class FirewallException < BackendException
  def initialize(error_string = '')
    super "Firewall configuration saving error."
    @error_string = error_string
  end

  def to_xml(options={})
    no_arg_to_xml(options,"GENERAL", "Firewall error: '#{@error_string}'.")
  end
end
