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
    # set context defaults
    @context = { 'yastcall'     => 1,
                 'norefresh'    => 1,
                 'restoreRepos' => 1,
                 'forcereg'     => 0,
                 'nohwdata'     => 1,
                 'nooptional'   => 1,
                 'logfile'      => '/root/.suse_register.log' }

    # merge custom context data
    if hash.class.to_s == 'Hash'
      @context.merge hash
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
    puts "-> called registration.register"
    # @reg = YastService.Call("YSR::statelessregister", { 'ctx' => @context, 'arguments' => @arguments } )
    @reg = YastService.Call("YSR::statelessregister", { } )
    puts "-> YSR::stateless_register was called"
    puts @reg.inspect
    return @reg.inspect
  end

  def get_registration_config
    return @reg.inspect
  end

  def set_registration_config(url, ca)
    # TODO: write registration config
    return @reg.inspect
  end


  def to_xml
    return @reg if @reg.class.to_s == String
    return "<regtest>#{ @reg.to_s }</regtest>"
  end

  def to_xml( options = {} )
    #return "This function outputs XML :)"

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
