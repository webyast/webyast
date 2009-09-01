
# parent of all rest-service related exception.
# Main goal is to provide to_xml method to report it in response.
class BackendException < StandardError

  def to_xml()
    no_arg_to_xml("GENERAL", "Universal error, should be redefined.")
  end

  protected
  #create xml without arguments, so only error type and description
  def no_arg_to_xml(type,descr)
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type type
      xml.description descr
    end

  end

end

class NoPermissionException < BackendException
  def initialize(permission,user)
    @permission = permission
    @user = user
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

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

  def to_xml
    no_arg_to_xml("NOT_LOOGED", "No one is logged to rest service.")
  end
end

class PolicyKitException < BackendException
  def initialize(message,user,permission)
    @message = message
    @user = user
    @permission = permission
    super("Policy kit exception for user #{user} and permission #{permission}: #{message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "POLKIT"
      xml.description message
      xml.polkitout @message
      xml.user @user
      xml.permission @permission
    end
  end
end
