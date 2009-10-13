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
    @context = { 'yastcall'     => [ 'i', 1 ],
                 'norefresh'    => [ 'i', 1 ],
                 'restoreRepos' => [ 'i', 1 ],
                 'forcereg'     => [ 'i', 0 ],
                 'nohwdata'     => [ 'i', 1 ],
                 'nooptional'   => [ 'i', 1 ],
                 'debugMode'    => [ 'i', 2 ],
                 'logfile'      => [ 's', '/root/.suse_register.log' ] }

    # when hash is nil, ignore it
    return if hash.nil?

    # merge custom context data
    if hash.class.to_s == 'Hash'
       @context.merge hash
    else
      raise "Invalid or missing registration initialization context data."
    end

  end

  def find 
    # Fixme: get the uuid, server url and certificate -> to be done in YSR.pm
    return {}
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
    # @reg = YastService.Call("YSR::statelessregister", { 'ctx' => @context, 'arguments' => @arguments } )
    # don't know how to pass only one hash, so split it into two. FIXME change later if possible!
    @reg = YastService.Call("YSR::statelessregister", @context, {} )
    # return @reg.inspect
  end

  def get_registration_config
    # return @reg.inspect
  end

  def set_registration_config(url, ca)
    # TODO: write registration config
    # return @reg.inspect
  end


  def to_xml
    return @reg if @reg.class.to_s == String
    return "<regtest>#{ @reg.to_s }</regtest>"
  end

  def to_xml( options = {} )
    #return "This function outputs XML :)"

    # FIXME only for testing!!
    return @reg.inspect

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
