#
# Permission class
#
require 'exceptions'
require 'polkit'

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
    @permissions.collect! do
      |perm| 
      begin
        if PolKit.polkit_check( perm[:id], user) == :yes
          perm[:granted] = true
          Rails.logger.debug "Action: #{perm[:id]} User: #{user} Result: ok"
        else
          perm[:granted] = false
          Rails.logger.debug "Action: #{perm[:id]} User: #{user} Result: NOT granted"
        end
      rescue RuntimeError => e
        Rails.logger.info e
        if e.message.include?("does not exist")
          raise InvalidParameters.new :user_id => "UNKNOWN" 
        else
          raise PolicyKitException.new(e.message, user, perm[:id])
        end
      rescue Exception => e
        Rails.logger.info e
        raise
      end
      perm
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
      raise InvalidParameters.new(:user_id => "INVALID")
    end
  end

  def all_actions
    `/usr/bin/polkit-action`
  end

  def filter_nonsuse_permissions (str)
    suse_string = "org.opensuse.yast"
    str.select{ |s| s.include? suse_string }
  end

end
