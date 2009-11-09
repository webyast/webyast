#
# Permission class
#
require 'exceptions'

class Permission
#list of hash { :name => id, :granted => boolean}
  attr_reader :permissions

  def initialize
    @permissions = []
  end

  def self.find(type,restrictions={})
    permission = Permission.new
    permission.load_permissions restrictions
    user = restrictions[:user_id]
    permission.mark_granted_permissions_for_user user if user
    return permission
  end

  def save
    raise "Unimplemented"
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.permissions(:type => "array") do 
      @permissions.each do
        |perm| perm.to_xml({:builder => xml, :skip_instruct => true, :root => "permission"})
      end
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

  def load_permissions(options)
    semiresult = all_actions.split(/\n/)
    semiresult = filter_nonsuse_permissions semiresult
    if (options[:filter])
      semiresult.delete_if { |perm| !perm.include? options[:filter] }
    end
  @permissions = semiresult.map do
    |value|
      {
        :id => value,
        :granted => false
      }
    end
  end

  def mark_granted_permissions_for_user(user)
    res = actions_for_user(user).split(/\n/)
    res = filter_nonsuse_permissions res
    res.each do
      |permission|
      #not much effective n*m where n is count of permissions and
      # m is count of granted permissions
      val = @permissions.detect do
        |value| value[:id]==permission
      end
      val[:granted] = true if val
    end
  end
private

  USERNAME_REGEX = /\A[\d\w_]+\z/
  #
  # check if the username is valid (letters, digits, underscores)
  #
  #
  
  def check_username user
    unless user =~ USERNAME_REGEX
      raise InvalidParameters :user_id => "INVALID" 
    end
  end

  def actions_for_user(user_name)
    check_username user_name
    ret = `LC_ALL=C polkit-auth --user '#{user_name}'` #whitelist usernames so this is secure
    Rails.logger.info ret
    if $?.exitstatus != 0 || ret.include?("cannot look up uid for user")
      Rails.logger.info "status: #{$?.exitstatus} unknown user:"+ret
      raise InvalidParameters :user_id => "UNKNOW" 
    end
    return ret || []
  end

  def all_actions
    `polkit-action`
  end

  def filter_nonsuse_permissions (str)
    suse_string = "org.opensuse.yast"
    str.select{ |s| s.include? suse_string }
  end

end
