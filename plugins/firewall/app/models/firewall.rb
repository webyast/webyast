class Firewall < BaseModel::Base

  attr_accessor :use_firewall, :services

  def self.find
    Firewall.new YastService.Call("YaPI::FIREWALL::Read")
  end

end
