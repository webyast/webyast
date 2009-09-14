require 'singleton'
require 'yast_service'

class Administrator

  attr_accessor	:aliases
  attr_reader	:password

  include Singleton

  def initialize
    @aliases	= ""
    @password	= ""
  end

  def read_aliases
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Read")
    if yapi_ret.nil?
      raise "Can't read administrator data"
    elsif yapi_ret.has_key?("aliases")
      @aliases	= yapi_ret["aliases"].join(",")
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
    new_aliases = "" if new_aliases.nil?
    if @aliases.split(",").sort == new_aliases.split(",").sort
      Rails.logger.debug "mail aliases have not been changed"
      return
    end
    parameters	= {
      "aliases" => ["as", new_aliases.split(",")]
    }
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"

    raise yapi_ret unless yapi_ret.empty?
    @aliases = new_aliases
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.administrator do
      xml.password password
      xml.aliases aliases
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

end
