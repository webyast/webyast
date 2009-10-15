# = Registration model
# Provides methods to call the registration in a RESTful environment.
# The main goal is to provide easy access to the registration workflow,
# the caller must interpret the result and maybe call it again with 
# changed values.
class Registration

  require 'yast_service'

  @context = { }
  @arguments = { }
  @config = { }
  @reg = ''

  def initialize(hash)
    # cleanup arguments
    @arguments = { 'test' => [ 'a{ss}', { 'value' => 'mytestvalue' } ] }
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
    raise "Invalid or missing registration initialization context data." unless hash.is_a?(Hash)
    
    hash.each do |k, v|
      @context.merge!( { k => ['s', v.to_s] } )
    end

  end

  def find
    begin
      @config = YastService.Call("YSR::getregistrationconfig")
    rescue Exception => e
      Rails.logger.error "YastService.Call('YSR::getregistrationconfig') failed"
      raise
    end
    @config
  end

  def set_context(hash)
    self.initialize hash
  end

  def add_argument(key, value)
    @arguments.merge!( { key => [ 'a{ss}',{ 'value' => "#{value.to_s}" } ] } )
  end

  def add_arguments(hash)
    hash.each {|k, v| self.add_argument k, v }
  end

  def set_arguments(hash)
    @arguments = {}
    self.add_arguments hash
  end


  def register
    # don't know how to pass only one hash, so split it into two. FIXME change later if possible!
    # @reg = YastService.Call("YSR::statelessregister", { 'ctx' => @context, 'arguments' => @arguments } )

    @reg = YastService.Call("YSR::statelessregister", @context, @arguments )
    return @reg['exitcode'] || 99
  end

  def get_config
    find
  end

  def set_config(url, ca)
    newconfig = { 'regserverurl' => url,
                  'regserverca'  => ca  }
    ret = YastService.Call("YSR::setregistrationconfig", newconfig)
    puts "YastService.Call returned: =#{ret}="
    self.get_config
    return ret
  end

  def status_to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registration do
      xml.tag!(:guid, @config['guid']) if @config['guid'] && @config['guid'].size > 0
    end
  end

  def config_to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registrationconfig do
      xml.server do
        xml.tag!(:url, @config['regserverurl'] )
      end
     xml.certificate do
       xml.data do
         xml.cdata!(@config['regserverca']) if @config['regserverca'].size > 0
       end
     end
    end
  end


  def to_xml( options = {} )
    # TODO  FIXME ... create the registration xml structure
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

  def status_to_json( options = {} )
    hash = Hash.from_xml(status_to_xml())
    return hash.to_json
  end

  def config_to_json( options = {} )
    hash = Hash.from_xml(config_to_xml())
    return hash.to_json
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end


end
