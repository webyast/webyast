
# parent of all rest-service related exception.
# Main goal is to provide to_xml method to report it in response.
class BackendException < StandardError

  def to_xml(options={})
    no_arg_to_xml(options,"GENERAL", "Universal error, should be redefined.")
  end

  protected
  #create xml without arguments, so only error type and description
  def no_arg_to_xml(options,type,descr)
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.error do
      xml.type type
      xml.description descr
    end

  end

end

# Exception that reports invalid arguments
# initialized by constrains which is broken
# If uncatched then response 422 and cause fail of ActiveResouce#save
class InvalidParameters < ArgumentError
  # Takes as argument constrains. Constrains is hash where key is parameter
  # and value is broken constrain
  # (it is not translated so should be some symbol, which is then on frontend
  #  readed and reported translated message)
  #
  # example::
  #   raise InvalidParameters.new {
  #      :email => "MISSING"
  #   }
  def initialize (constrains)
    @constrains = constrains
    super("Invalid arguments: #{@constrains.inspect}")
  end

  # Creates standartized xml for ActiveResource validation - http://railsbrain.com/api/rails-2.3.2/doc/index.html?a=C00000626&name=Base
  # error is reported in format '<humanized argument name> --- <error identificator>
  def to_xml(options={})
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.errors(:type => "array") do
      @constrains.each {
        |k,v|
        xml.error "#{k.to_s.humanize} --- #{v}"
      }
    end
  end
end

class NoPermissionException < BackendException
  def initialize(permission,user)
    @permission = permission
    @user = user
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.error do
      xml.type "NO_PERM"
      xml.description "Permission to allow #{@permission} is not available for user #{@user}"
      xml.permission @permission
      xml.user @user
    end
  end
end

class NotLoggedException < BackendException
  def initialize()
    super("No one is logged.")
  end

  def to_xml(options={})
    no_arg_to_xml(options,"NOT_LOGGED", "No one is logged to rest service.")
  end
end

class PolicyKitException < BackendException
  def initialize(message,user,permission)
    @message = message
    @user = user
    @permission = permission
    super "Policy kit exception for user #{user} and permission #{permission}: #{message}."
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.error do
      xml.type "POLKIT"
      xml.description message
      xml.polkitout @message
      xml.user @user
      xml.permission @permission
    end
  end
end

# Exception that signalizes that target file is missing or corrupted
# for bad configuration in file use own exception with better explanation what is wrong
class CorruptedFileException < BackendException
  def initialize(file)
    @file = file
    super "Target system is not consistent: Missing or corrupted file #{@file}"
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.error do
      xml.type "BADFILE"
      xml.description message
      xml.file @file
    end
  end
end

# Exception that signalizes that the requested path does not point to a directory
class NotADirException < BackendException
  def initialize(file)
    @file = file
    super "File error: Path #{@file} does not point to a directory"
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.error do
      xml.type "NOTADIR"
      xml.description message
      xml.file @file
    end
  end
end

# Exception, which signalizes, that some functionality of backend was requested
# without accepting the EULA first.
class EulaNotAcceptedException < BackendException
  def initialize()
    super("EULA not yet accepted.")
  end

  def to_xml(options={})
    no_arg_to_xml(options,"EULA_NOT_ACCEPTED", "Functionality of the target system was required, but its EULA was not accepted yet.")
  end
end

class ServiceNotAvailable < BackendException
  def initialize(service)
    @service = service
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.error do
      xml.type "SERVICE_NOT_AVAILABLE"
      xml.description "#{@service} is not available on the target machine"
      xml.service @service
    end
  end
end

class ServiceNotRunning < BackendException
  def initialize(service)
    @service = service
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    xml.error do
      xml.type "SERVICE_NOT_RUNNING"
      xml.description "#{@service} is not running on the target machine"
      xml.service @service
    end
  end
end

