# = Register model
# Provides methods to call the registration in a RESTful environment.
# The main goal is to provide easy access to the registration workflow,
# the caller must interpret the result and maybe call it again with 
# changed values.

# Hash.from_xml converts dashes in keys to underscores
#  by this we can not find out the correct key name (whether it was a dash or an underscore)
#  unfortunately the regcode keys in registration make excessive use of dashes AND underscores
#  that way the information gets lost what key to assign the correct value.
#  So the function "unrename_keys" will be overwritten
class HashWithoutKeyConversion < Hash; end
HashWithoutKeyConversion.class_eval do
   def self.unrename_keys(params)
      case params.class.to_s
        when "Hash"
          params.inject({}) do |h,(k,v)|
            h[k.to_s] = unrename_keys(v)
            h
          end
        when "Array"
          params.map { |v| unrename_keys(v) }
        else
          params
         end
  end
end

class Register

  require 'yast_service'

  attr_accessor :registrationserver
  attr_accessor :certificate
  attr_accessor :context
  attr_accessor_with_default :arguments, Hash.new
  attr_reader   :guid

  @reg = {}

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
                 'nohwdata'     => '0',
                 'nooptional'   => '0',
                 'debug'        => '2',
                 'logfile'      => Paths::REGISTRATION_LOG }
    @context.merge! hash if hash.kind_of?(Hash)
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
      self.context.each   { |k, v|  ctx[k.to_s] = [ 's', v.to_s ] } if self.context.kind_of?(Hash)
      self.arguments.each { |k, v| args[k.to_s] = [ 's', v.to_s ] } if self.arguments.kind_of?(Hash)
    rescue
      Rails.logger.error "When registration was called, the context or the arguments data was invalid."
      raise InvalidParameters.new :registrationdata => "Invalid"
    end

    @reg = YastService.Call("YSR::statelessregister", ctx, args )
    Rails.logger.debug "registration server returns: #{@reg.inspect}"
    @arguments = HashWithoutKeyConversion.from_xml(@reg['missingarguments']) if @reg && @reg.has_key?('missingarguments')
    @arguments = @arguments["missingarguments"] if @arguments && @arguments.has_key?('missingarguments')

    @reg['exitcode'].to_i rescue 99
  end

  def save
    newconfig = { 'regserverurl' => registrationserver,
                  'regserverca'  => certificate  }
    ret = YastService.Call("YSR::setregistrationconfig", newconfig)
    self.find
    return ret
  end

  def status_to_xml( options = {} )
    find
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registration do
      xml.guid @guid if @guid && @guid.size > 0
    end
  end

  def config_to_xml( options = {} )
    find
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
    find
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    exitcode = if !@reg                        then 99
               elsif @reg.has_key?('exitcode') then @reg['exitcode'].to_i
                                               else 199
               end

    status = if !@reg || @reg['error']                   then  'error'
             elsif @reg['missinginfo'] && exitcode == 4  then  'missinginfo'
             elsif @reg['success']                       then  'finished'
                                                         else  'error'
             end

    changedrepos = {}
    changedservices = {}

    tasklist = HashWithoutKeyConversion.from_xml @reg['tasklist'] if @reg && @reg['tasklist']

    if ( tasklist && tasklist.has_key?('tasklist') && tasklist['tasklist'] &&
         tasklist['tasklist'].has_key?('item') && tasklist['tasklist']['item'] )
    then
      tasklist_hash = Hash.new
      item = tasklist['tasklist']['item']

      case item
      when Hash, HashWithIndifferentAccess
        tasklist_hash[item['ALIAS']] = item if item.has_key?('ALIAS')
      when Array
        item.each do |i|
          tasklist_hash[i['ALIAS']] = i if i.has_key?('ALIAS')
        end
      end

      changedrepos    = tasklist_hash.reject { | k, v |  !v.kind_of?(Hash) || v['TYPE'] != 'zypp' }
      changedservices = tasklist_hash.reject { | k, v |  !v.kind_of?(Hash) || v['TYPE'] != 'nu' }
    end


    tasknic = { 'a'  => 'added',         'd' => 'deleted',
                'le' => 'leave enabled', 'ld' => 'leave disabled'}

    xml.registration do
      xml.status status
      xml.exitcode exitcode
      xml.guid self.guid || ''

      if @arguments && @arguments.size > 0 && exitcode == 4
        xml.missingarguments({:type => "array"}) do
          @arguments.each do | k, v |
            if k && v.kind_of?(Hash)
              xml.argument do
                xml.name k
                xml.value v['value']
                xml.flag v['flag']
                xml.kind v['kind']
              end
            end
          end
        end
      end

      if changedrepos && changedrepos.size > 0
        xml.changedrepos({:type => "array"}) do
          changedrepos.each do | k, v |
            if k && v && v.kind_of?(Hash) && v.has_key?('TASK') && v['TASK'] != "le" && v['TASK'] != "ld" #only changed repos
              xml.repo do
                xml.name v['ALIAS'] || ''
                xml.alias v['ALIAS'] || ''
                xml.type v['TYPE']  || ''
                xml.url v['URL'] || ''
                xml.status tasknic[ v['TASK'] ] || ''
              end
            end
          end
        end
      end
      if changedservices && changedservices.size > 0
        xml.changedservices({:type => "array"}) do
          changedservices.each do | k, v |
            if k && v.kind_of?(Hash)
              xml.service do
                xml.name v['ALIAS'] || ''
                xml.alias v['ALIAS'] || ''
                xml.type v['TYPE']  || ''
                xml.url v['URL'] || ''
                xml.status tasknic[ v['TASK'] ] || ''
                if v['CATALOGS']
                  xml.catalogs do
                    if v['CATALOGS'].kind_of?(Hash) && v['CATALOGS']['catalog'] && v['CATALOGS']['catalog'].kind_of?(Array) && v['CATALOGS']['catalog'].size > 0
                      v['CATALOGS']['catalog'].each do |l|
                        if l && l.kind_of?(Hash)
                          xml.catalog do
                            xml.name l['NAME'] || ''
                            xml.alias l['ALIAS'] || ''
                            xml.status tasknic[ l['TASK'] ] || ''
                          end
                        end
                      end
                    #It is an hash only. This is produced by hash.form_xml if catalogs contains ONE entry only
                    elsif v['CATALOGS'].kind_of?(Hash) && v['CATALOGS']['catalog'] && v['CATALOGS']['catalog'].kind_of?(Hash)
                      xml.catalog do
                        xml.name v['CATALOGS']['catalog']['NAME'] || ''
                        xml.alias v['CATALOGS']['catalog']['ALIAS'] || ''
                        xml.status tasknic[ v['CATALOGS']['catalog']['TASK'] ] || ''
                      end
                    else
                      xml.catalog ''
                    end
                  end
                end # catalogs
              end
            end
          end # services.each
        end
      end # changedservices
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
