# = Registration model
# Provides methods to call the registration in a RESTful environment.
# The main goal is to provide easy access to the registration workflow,
# the caller must interpret the result and maybe call it again with 
# changed values.
class Registration

  require 'yast_service'

  @context = { }
  @arguments = { }
  @reg = ''

  def initialize(hash)
    if hash.class.to_s == 'Hash'
      @context = hash
    else
      raise "Invalid or missing registration initialization context data."
    end
  end

  def set_context(hash)
    self.initialize hash
  end

  def set_arguments(hash)
    @arguments = hash
  end

  def add_arguments(hash)
    @arguments.merge hash
  end

  def register
    @reg = YastService.Call("YSR::stateless_register", @context )
  end

  def get_registration_server_details
    @reg = "get-reg-srv-det"
  end

  def set_registration_server_details(url, ca)
    @reg = "you want to set URL: #{ url }"
  end


  def to_xml
    return @reg if @reg.class.to_s == String
    return "<regtest>#{ @reg.to_s }</regtest>"
  end

  def to_xml( options = {} )
    #return "This function should output XML"

    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registration do
      xml.tag!(:info, "infotest")
      xml.tag!(:foobar, "foobartest" )
      xml.arguments({:type => "array"}) do
        { "eins" => 1, "zwei" => 2, "drei" => 3 }.each do |k,v|
          xml.argument do
            xml.tag!( :name, k)
            xml.tag!( :value, v)
          end
        end
      end
    end
  end

end
