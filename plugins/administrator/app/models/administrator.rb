require 'singleton'
require 'yast_service'

class Administrator

  attr_reader	:aliases

  include Singleton

  def initialize
    @aliases	= []
  end

  def read_aliases
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Read")
    if yapi_ret.nil?
      raise "Can't read administrator data"
    elsif yapi_ret.has_key?("aliases")
      @aliases	= yapi_ret["aliases"]
    end
    @aliases
  end

  def save_password(pw)
    Rails.logger.debug "--------------------- saving password #{pw}--------"
  end

  def save_aliases(new_aliases)
    # TODO compare new_aliases with aliases
    Rails.logger.debug "--------------------- current aliases #{aliases.inspect}"
    Rails.logger.debug "--------------------- saving aliases #{new_aliases.inspect}"
    @aliases = new_aliases
  end

end
