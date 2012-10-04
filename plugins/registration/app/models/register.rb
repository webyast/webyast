#--
# Copyright (c) 2009-2010 Novell, Inc.
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

# = Register model
# Provides methods to call the registration in a RESTful environment.
# The main goal is to provide easy access to the registration workflow,
# the caller must interpret the result and maybe call it again with
# changed values.

require 'yast/paths'
require 'builder'

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
  attr_accessor :arguments

  attr_reader   :guid
  attr_reader   :config_error
  attr_reader   :status
  attr_reader   :changedrepos
  attr_reader   :changedservices
  attr_reader   :missingarguments
  attr_reader   :invaliddataerrormessage

  @reg = {}

private

  def read_status
    begin
      config = YastService.Call("YSR::getregistrationconfig")
      @registrationserver = config['regserverurl']
      @certificate = config['regserverca']
      @guid = config['guid'] unless config['guid'].blank?
    rescue Exception => e
      # catch the error of  missing YSR function(s)
      # in case a wrong yast2-registration version is installed
      # TODO: catch error cases of YastService.Call individually and write more detailed log
      Rails.logger.error "YastService.Call('YSR::getregistrationconfig') failed with #{e}"
      @config_error = true
      return false
    end
    config
  end

public


  def initialize(hash={})
    @paarguments = Hash.new #attr_accessor_with_default :arguments, Hash.new

    # initialize context
    init_context hash
    # read the configuration
    read_status
  end

  def init_context(hash)
    # set context defaults
    @context = { 'yastcall'     => '1',
                 'norefresh'    => '1',
                 'restoreRepos' => '1',
                 'nohwdata'     => '0',
                 'nooptional'   => '0',
                 'debug'        => '2',
                 'logfile'      => YaST::Paths::REGISTRATION_LOG }

    # read system proxy settings and set proxy in the suseRegister context (bnc#626965)
    sc_proxy = "/etc/sysconfig/proxy"
    proxy_enabled = `grep "^[[:space:]]*PROXY_ENABLED[[:space:]]*=" #{sc_proxy} | head -1 `.to_s.chomp.sub(/^[^=]*=\s*"(.*)".*$/, '\1') # RORSCAN_ITL
    http_proxy    = `grep "^[[:space:]]*HTTP_PROXY[[:space:]]*="    #{sc_proxy} | head -1 `.to_s.chomp.sub(/^[^=]*=\s*"(.*)".*$/, '\1') # RORSCAN_ITL
    https_proxy   = `grep "^[[:space:]]*HTTPS_PROXY[[:space:]]*="   #{sc_proxy} | head -1 `.to_s.chomp.sub(/^[^=]*=\s*"(.*)".*$/, '\1') # RORSCAN_ITL

    # set proxy settings in context for suseRegister backend
    if proxy_enabled.match %r/^yes$/i then
      @context['proxy-http_proxy']  = http_proxy
      @context['proxy-https_proxy'] = https_proxy
    end

    # last action: overwrite the context settings with the settings that were sent with the request
    @context.merge! hash if hash.kind_of?(Hash)
  end

  def is_registered?
    begin
      return ( @guid  &&  @guid.size > 0  &&  @guid != 0 ) == true
    rescue
      Rails.logger.error "Error when reading the registration status information. The GUID could not be determined."
      return false
    end
  end

  def register
    # don't know how to pass only one hash, so split it into two. TODO change later if possible!
    # @reg = YastService.Call("YSR::statelessregister", { 'ctx' => ctx, 'arguments' => args } )

    ctx = Hash.new
    args = Hash.new
    begin
      self.context.each   { |k, v|  ctx[k.to_s] = [ 's', v.to_s ] } if self.context.kind_of?(Hash)
      self.arguments.each { |k, v| args[k.to_s] = [ 's', v.to_s ] } if self.arguments.kind_of?(Hash)
    rescue
      Rails.logger.error "When registration was called, the context or the arguments data was invalid."
      Rails.logger.error "Registration Context Data: #{ self.context.inspect }"
      Rails.logger.error "Registration Argument Data: #{ self.arguments.inspect }"
      raise InvalidParameters.new :registrationdata => "Invalid"
    end

    @reg = YastService.Call("YSR::statelessregister", ctx, args )
# @reg = {"manualurl"=>"https://secure-www.novell.com/center/regsvc-1.0/?lang=en-US&guid=dfe61a4b5f0948c6bd00bc47c6d338ab&command=interactive", "errorcode"=>"0", "exitcode"=>"4", "readabletext"=>"To complete the registration, provide some additional parameters:\n\n\nYou can provide these parameters with the '-a' option.\nYou can use the '-a' option multiple times.\n\nExample:\n\nsuse_register -a email=\"me@example.com\"\n\nTo register your product manually, use the following URL:\n\nhttps://secure-www.novell.com/center/regsvc-1.0/?lang=en-US&guid=dfe61a4b5f0948c6bd00bc47c6d338ab&command=interactive\n\n\nInformation on Novell's Privacy Policy:\nSubmit information to help you manage your registered systems.\nhttp://www.novell.com/company/policies/privacy/textonly.html\n", "missinginfo"=>"Missing Information", "missingarguments"=>"<missingarguments>\n  <platform flag=\"i\" kind=\"mandatory\" value=\"x86_64\" />\n  <processor flag=\"i\" kind=\"mandatory\" value=\"x86_64\" />\n  <timezone flag=\"i\" kind=\"mandatory\" value=\"Europe/Prague\" />\n</missingarguments>\n"}

    Rails.logger.debug "registration server returns: #{@reg.inspect}"

    @missingarguments = []
    if @reg && @reg.has_key?('missingarguments')
      arguments_hash = HashWithoutKeyConversion.from_xml(@reg['missingarguments'])
      arguments_hash['missingarguments'].each do | k, v |
        @missingarguments << { "name" => k, "value" => v['value'], "flag" => v['flag'], "kind" => v['kind'] } if v.kind_of?(Hash)
      end
    end

    @invaliddataerrormessage = @reg['invaliddataerrormessage'] || ""

    if !@reg.kind_of?(Hash)
      exitcode = 99
      @reg = Hash.new
    elsif @reg.has_key?('error') && @reg.has_key?('errorcode')
      exitcode = @reg['errorcode'].to_i
      exitcode = 199 if exitcode == 0
    elsif @reg.has_key?('exitcode')
      exitcode = @reg['exitcode'].to_i
      exitcode = 199 if (exitcode == 0 && @reg['exitcode'] != "0")
    else
      exitcode = 199
    end

    @status = if !@reg || @reg['error']                   then  'error'
              elsif @reg['missinginfo'] && exitcode == 4  then  'missinginfo'
              elsif @reg['success']                       then  'finished'
                                                          else  'error'
              end

    repos = {}
    services = {}

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

      repos    = tasklist_hash.reject { | k, v |  !v.kind_of?(Hash) || v['TYPE'] != 'zypp' }
      services = tasklist_hash.reject { | k, v |  !v.kind_of?(Hash) || v['TYPE'] != 'nu' }
    end

    tasknic = { 'a'  => 'added',         'd' => 'deleted',
                'le' => 'leave enabled', 'ld' => 'leave disabled'}
    @changedrepos = []
    repos.each do | k, v |
      if k && v && v.kind_of?(Hash) && v.has_key?('TASK') && v['TASK'] != "le" && v['TASK'] != "ld" #only changed repos
        @changedrepos << { :name   => v['ALIAS'] || '',
                           :alias  => v['ALIAS'] || '',
                           :type   => v['TYPE']  || '',
                           :url    => v['URL'] || '',
                           :status => tasknic[ v['TASK'] ] || ''}
      end
    end
    @changedservices = []
    services.each do | k, v |
      if k && v.kind_of?(Hash)
        catalogs = []
        if v['CATALOGS']
          if v['CATALOGS'].kind_of?(Hash) && v['CATALOGS']['catalog'] && v['CATALOGS']['catalog'].kind_of?(Array) && v['CATALOGS']['catalog'].size > 0
            v['CATALOGS']['catalog'].each do |l|
              if l.kind_of?(Hash)
                catalogs << { :name   => l['NAME'] || '',
                              :alias  => l['ALIAS'] || '',
                              :status => tasknic[ l['TASK'] ] || '' }
              end
            end
          #It is an hash only. This is produced by hash.form_xml if catalogs contains ONE entry only
          elsif v['CATALOGS'].kind_of?(Hash) && v['CATALOGS']['catalog'] && v['CATALOGS']['catalog'].kind_of?(Hash)
            catalogs << { :name   => v['CATALOGS']['catalog']['NAME'] || '',
                          :alias  => v['CATALOGS']['catalog']['ALIAS'] || '',
                          :status => tasknic[ v['CATALOGS']['catalog']['TASK'] ] || '' }
          end
        end # catalogs
        @changedservices << { :name     => v['ALIAS'] || '',
                              :alias    => v['ALIAS'] || '',
                              :type     => v['TYPE']  || '',
                              :url      => v['URL'] || '',
                              :status   => tasknic[ v['TASK'] ] || '',
                              :catalogs => catalogs }
      else
        Rails.logger.error "Cannot evaluate service: #{k}, #{v.inspect}"
      end
    end # services.each

    @reg['calculated_exitcode'] = exitcode
    exitcode
  end

  def save
    newconfig = { 'regserverurl' => registrationserver,
                  'regserverca'  => certificate  }
    ret = YastService.Call("YSR::setregistrationconfig", newconfig)
    read_status
    return ret
  end

  def status_to_xml( options = {} )
    read_status
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.registration do
      xml.guid @guid if self.is_registered?
      xml.configerror 'true' if @config_error == true
    end
  end

  def config_to_xml( options = {} )
    read_status
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.registrationconfig do
      xml.configerror 'true' if @config_error == true
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
    read_status
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    exitcode = (@reg['calculated_exitcode'] if @reg) || 199

    # catch error 2 and pass error message on (bnc#604777)
    invaliddatamessage = if ( exitcode == 2  && @reg &&  !@reg['invaliddataerrormessage'].blank? ) then
      @reg['invaliddataerrormessage']
    else
      nil
    end

    xml.registration do
      xml.status @status
      xml.exitcode exitcode
      xml.invaliddataerrormessage invaliddatamessage if !invaliddatamessage.blank?
      xml.guid self.guid || ''
      if !@missingarguments.blank? && exitcode == 4
        xml.missingarguments({:type => "array"}) do
          @missingarguments.each do | v |
            if v.kind_of?(Hash)
              xml.argument do
                xml.name v['name']
                xml.value v['value']
                xml.flag v['flag']
                xml.kind v['kind']
              end
            end
          end
        end
      end

      unless @changedrepos.blank?
        xml.changedrepos({:type => "array"}) do
          @changedrepos.each do | v |
            xml.repo do
              xml.name v[:name] || ''
              xml.alias v[:alias] || ''
              xml.type v[:type]  || ''
              xml.url v[:url] || ''
              xml.status v[:status] || ''
            end
          end
        end
      end

      unless @changedservices.blank?
        xml.changedservices({:type => "array"}) do
          @changedservices.each do | v |
            xml.service do
              xml.name v[:name] || ''
              xml.alias v[:alias] || ''
              xml.type v[:type]  || ''
              xml.url v[:url] || ''
              xml.status v[:status] || ''
              xml.catalogs do
                v[:catalogs].each do |l|
                  xml.catalog do
                    xml.name l[:name] || ''
                    xml.alias l[:alias] || ''
                    xml.status l[:status] || ''
                  end
                end
              end
            end
          end
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
