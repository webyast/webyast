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
                 'forcereg'     => '1',
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
      self.context.each   { |k, v|  ctx[k.to_s] = [ 's', v.to_s ] }
#puts "CCCCCCCCCCCCCTX #{ctx.inspect}"
      self.arguments.each { |k, v| args[k.to_s] = [ 's', v.to_s ] }
#puts "AAAAAAAAAAAARGS #{args.inspect}"
    rescue
      Rails.logger.error "When registration was called, the context or the arguments data was invalid."
      raise InvalidParameters.new :registrationdata => "Invalid"
    end

    @reg = YastService.Call("YSR::statelessregister", ctx, args )

#puts "xxxxxxxxxxxxxxATREG: #{@reg.inspect}"

    # SCHUBI !! SCHUBI !! SCHUBI
    # FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME
    # Hash.from_xml converts dashes in keys to underscores
    #  by this we can not find out the correct key name (whether it was a dash or an underscore)
    #  unfortunately the regcode keys in registration make excessive use of dashes AND underscores
    #  that way the information gets lost what key to assign the correct value
    # This needs urgently to be fixed
    @arguments = Hash.from_xml(@reg['missingarguments']) if @reg && @reg.has_key?('missingarguments')
#puts "ARGS after XML transformation #{@arguments.inspect}\n"
    @arguments = @arguments["missingarguments"] if @arguments && @arguments.has_key?('missingarguments')

    # UGLY WORKAROUND
    @arguments.each { | k, v |  
      if k =~ /_/ 
        @arguments[ k.sub(/_/, '-')  ] = v   
        @arguments.delete k  
      end   
    }


#puts "ARGS after correction #{@arguments.inspect}\n"
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
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    status = if !@reg ||  @reg['error'] then  'error'
             elsif @reg['missinginfo']  then  'missinginfo'
             elsif @reg['success']      then  'finished'
             end

    tasklist = Hash.from_xml @reg['tasklist'] if @reg && @reg['tasklist']
    changedrepos    = tasklist.collect { | k, v |  v.class == Hash && v['TYPE'] == 'zypp'  } if tasklist
    changedservices = tasklist.collect { | k, v |  v.class == Hash && v['TYPE'] == 'nu'  } if tasklist
    tasknic = { 'a'  => 'added',         'd' => 'deleted',
                'ld' => 'leave enabled', 'ld' => 'leave disabled'}

# during development return static response
    xml.registration do
      if @reg then
        xml.status status
        xml.exitcode @reg['exitcode'] || ''
        xml.guid @reg['guid'] || ''

        if @arguments then
          xml.missingarguments({:type => "array"}) do
            @arguments.each do | k, v |
              if k && v.class == Hash
              then
                xml.argument do
                  xml.name k
                  xml.value v['value']
                  xml.flag v['flag']
                  xml.kind v['kind']
                  xml.type 'string'
                end
              end
            end
          end
        end

        if changedrepos
        then
          xml.changedrepos({:type => "array"}) do
            changedrepos.each do | k, v |
              if k && v.class == Hash
              then
                xml.repo do
                  xml.name v['NAME'] || ''
                  xml.alias v['ALIAS'] || ''
                  xml.type v['TYPE']  || ''
                  xml.url v['URL'] || ''
                  xml.status tasknic[ v['TASK'] ] || ''
                end
              end
            end
          end
        end

        if changedservices
        then
          xml.changedservices({:type => "array"}) do
            changedservices.each do | k, v |
              if k && v.class == Hash
              then
                xml.service do
                  xml.name v['NAME'] || ''
                  xml.alias v['ALIAS'] || ''
                  xml.type v['TYPE']  || ''
                  xml.url v['URL'] || ''
                  xml.status tasknic[ v['TASK'] ] || ''
                  if v['CATALOGS']  &&  v['CATALOGS'].class == Hash
                  then
                    xml.catalogs do
                      v['CATALOGS'].each do |l, w|
                        if l && w.class == Hash
                        then
                          xml.catalog do
                            xml.name v['NAME'] || ''
                            xml.alias v['ALIAS'] || ''
                            xml.status tasknic[ v['TASK'] ] || ''
                          end
                        end
                      end
                    end
                  end # catalogs
                end
              end
            end # services.each
          end
        end # changedservices
      else
        xml.tag!(:status, 'error')
        xml.tag!(:exitcode, 1)
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
