#
# Configure PolicyKit permissions for a user
#

class PermissionsController < ApplicationController

  before_filter :login_required

  # before filter is called even when the action is cached
  before_filter :check_perms, :cache_valid, :only => :show

  # modify the cache path so it includes also the filter and user name parameters
  caches_action :show, :cache_path => Proc.new { |controller|
      ret = controller.controller_path + '/' + controller.params[:user_id] + '/' + controller.params[:filter]
      Rails.logger.info "Using cache path: #{ret}"
      ret
  }

  CACHE_ID = 'permissions:timestamp'

  def initialize
    @permissions = []
  end
  
  private
  
  #
  # check if logged in user requests his own stuff
  #
  def user_self( params )
    !params[:user_id].blank? && (params[:user_id] == self.current_account.login)
  end

  def check_perms
    unless user_self(params)
      permission_check "org.opensuse.yast.permissions.read"
    end
  end

  def get_cache_timestamp
    lst = [
      # the global config file
      File.mtime('/etc/PolicyKit/PolicyKit.conf'),
      # policies
      File.mtime('/usr/share/PolicyKit/policy/'),
      # explicit user authorizations
      File.mtime('/var/lib/PolicyKit/'),
      # default overrides
      File.mtime('/var/lib/PolicyKit-public/'),
    ]

    lst.delete_if { |item| item.nil? }

    lst.max.to_i
  end

  def cache_valid
    cache_timestamp = Rails.cache.read(CACHE_ID)
    current_timestamp = get_cache_timestamp

    if !cache_timestamp
        Rails.cache.write(CACHE_ID, current_timestamp)
    elsif cache_timestamp < current_timestamp
        Rails.logger.debug "#### Permissions cache expired"
        # expire all cached values using a regexp (for all users/filters)
        expire_fragment(%r{#{controller_path}/.*})
        Rails.cache.write(CACHE_ID, current_timestamp)
    end
  end

  public
#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------

  # permissions
  # GET /permissions/:user_id(.:format)

  def show
    # note: permission check is done in the check_perms before filter
    permission = Permission.find(:all,params)
    respond_to do |format|
      format.json { render :json => permission.to_json }
      format.xml { render :xml => permission.to_xml }
    end
  end

  # change permissions
  # PUT /permissions/:id(.:format)
  # nested within users
  # PUT /users/:user_id/permissions/:id(.:format)

  def update

  #implementation is wrong so mark as not implemented
  ret = { :error => "not implemented" }
    respond_to do |format|
      format.json { render :json => ret.to_json }
      format.xml { render :xml => ret.to_xml }
    end

  end

end
