# = Register model
# Provides methods to call the registration in a RESTful environment.
# The main goal is to provide easy access to the registration workflow,
# the caller must interpret the result and maybe call it again with 
# changed values.
class Register

  require 'yast_service'

  attr_accessor :registrationserver
  attr_accessor :certificate
  attr_accessor :context
  attr_accessor_with_default :arguments, Hash.new
  attr_reader   :guid

  @reg = ''

  def initialize(hash={})
    # initialize context
    init_context hash
    # read the configuration
    find
  end

  def init_context(hash)
    # set context defaults
    @context = { 'yastcall'     => '1',
                 'norefresh'    => '1',
                 'restoreRepos' => '1',
                 'forcereg'     => '0',
                 'nohwdata'     => '1',
                 'nooptional'   => '1',
                 'debugMode'    => '2',
                 'logfile'      => Paths::REGISTRATION_LOG }
    @context.merge! hash if hash.class == Hash
  end

  def find
    begin
      config = YastService.Call("YSR::getregistrationconfig")
      @registrationserver = config['regserverurl']
      @certificate = config['regserverca']
      @guid = config['guid']
    rescue Exception => e
      Rails.logger.error "YastService.Call('YSR::getregistrationconfig') failed"
      raise
    end
    config
  end

  def register
    # don't know how to pass only one hash, so split it into two. FIXME change later if possible!
    # @reg = YastService.Call("YSR::statelessregister", { 'ctx' => ctx, 'arguments' => args } )

    ctx = Hash.new
    args = Hash.new
    begin
      self.context.each   { |k, v|  ctx[k] = [ 's', v.to_s ] }
      self.arguments.each { |k, v| args[k] = [ 'a{ss}', { 'value' => v.to_s  } ] }
    rescue
      Rails.logger.error "When registration was called, the context or the arguments data was invalid."
      raise InvalidParameters.new :registrationdata => "Invalid"
    end

    @reg = YastService.Call("YSR::statelessregister", ctx, args )
    @reg['exitcode'] rescue 99
  end

  def save
    newconfig = { 'regserverurl' => registrationserver,
                  'regserverca'  => certificate  }
    ret = YastService.Call("YSR::setregistrationconfig", newconfig)

    self.find
    return ret
  end

  def status_to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registration do
      xml.guid @guid if @guid && @guid.size > 0
    end
  end

  def config_to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registrationconfig do
      xml.server do
        xml.url @registrationserver if @registrationserver
      end
     xml.certificate do
       xml.data do
         xml.cdata!(@certificate) if @certificate && @certificate.size > 0
       end
     end
    end
  end


  def to_xml( options = {} )
    # TODO  FIXME ... create the output based on parsed data
    # return static response during development

    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registration do
      if @reg then
        xml.tag!(:status, 'missinginfo')
        xml.tag!(:exitcode, 55)
        xml.tag!(:guid, "abcdefg1234567")


        xml.missingarguments({:type => "array"}) do
          xml.argument do
            xml.tag!(:name, 'regcode-SLES-13-SP5')
            xml.tag!(:type, 'string')
          end
          xml.argument do
            xml.tag!(:name, 'email')
            xml.tag!(:type, 'string')
          end
          xml.argument do
            xml.tag!(:name, 'moniker')
            xml.tag!(:type, 'string')
          end
        end

        xml.changedrepos ({:type => "array"})do
          xml.repo do
            xml.tag!(:name, 'foobar11n')
            xml.tag!(:alias, 'foobar11a')
            xml.tag!(:status, 'added')
          end
          xml.repo do
            xml.tag!(:name, 'foobar22n')
            xml.tag!(:alias, 'foobar22a')
            xml.tag!(:status, 'deleted')
          end
        end

        xml.changedservices ({:type => "array"})do
          xml.service do
            xml.tag!(:name, 'foobar33n')
            xml.tag!(:alias, 'foobar33a')
            xml.tag!(:status, 'deleted')
            xml.catalogs do
              xml.catalog do
                xml.tag!(:name, 'foobar44n')
                xml.tag!(:alias, 'foobar44a')
                xml.tag!(:status, 'enabled')
              end
              xml.catalog do
                xml.tag!(:name, 'foobar55n')
                xml.tag!(:alias, 'foobar55a')
                xml.tag!(:status, 'disabled')
              end # cat
            end # cats
          end # service 
        end # changedservices

      end # if reg
    end # xml-root
  end # func

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
