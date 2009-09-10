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
    parameters  = {
      "password" => ["s", pw ]
    }
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
  end

  def save_aliases(new_aliases)
    if @aliases.sort == new_aliases
      Rails.logger.debug "mail aliases have not been changed"
      return
    end
    parameters	= {
      "aliases" => ["as", new_aliases]
    }
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"

    raise yapi_ret unless yapi_ret.empty?
    @aliases = new_aliases
  end

end
