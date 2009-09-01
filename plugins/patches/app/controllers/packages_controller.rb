require 'singleton'

class PackagesController < ApplicationController

   before_filter :login_required

   # always check permissions and cache expiration
   # even if the result is already created and cached
   before_filter :check_read_permissions, :only => {:index, :show}
   before_filter :check_cache_status, :only => :index

   # cache 'index' method result
   caches_action :index

  private

  def check_read_permissions
    unless permission_check( "org.opensuse.yast.system.patches.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
  end

  # check whether the cached result is still valid
  def check_cache_status
    cache_timestamp = Rails.cache.read('patches:timestamp')

    if cache_timestamp.nil?
	# this is the first run, the cache is not initialized yet, just return
	Rails.cache.write('patches:timestamp', Time.now)
	return
    # the cache expires after 5 minutes, repository metadata
    # or RPM database update invalidates the cache immeditely
    # (new patches might be applicable)
    elsif cache_timestamp < 5.minutes.ago || cache_timestamp < Patch.mtime
	logger.debug "#### Patch cache expired"
	expire_action :action => :index, :format => params["format"]
	Rails.cache.write('patches:timestamp', Time.now)
    end
  end

  def compare_lists(packages)
    vendor_packages = Array.new
    #TODO: replace by real yml file
    package_list = ["3ddiag", "foo", "yast2-users", "yast2-network"]

    package_list.each {|pk_name|
      p = nil
      for i in 0..packages.size-1
        # package installed?
        if pk_name == packages[i].name
          # store package
          p = packages[i]
          break
        end
      end
      if p
        vendor_packages << p
      else
        vendor_packages << Package.new(:resolvable_id => 0, :name => pk_name, :version => "not_installed")
      end
    }
    vendor_packages
  end

  public

  # GET /patch_updates
  # GET /patch_updates.xml
  def index
    # note: permission check was performed in :before_filter
    @packages = Package.find(:installed)
    if params[:filter] == "custom"
      @packages = compare_lists(@packages)
    end
    respond_to do |format|
      format.html { render :xml => @packages.to_xml( :root => "packages", :dasherize => false ) }
      format.xml { render  :xml => @packages.to_xml( :root => "packages", :dasherize => false ) }
      format.json { render :json => @packages.to_json( :root => "packages", :dasherize => false ) }
    end
  end

  # GET /patch_updates/1
  # GET /patch_updates/1.xml
  def show
  end

  # PUT /patch_updates/1
  # PUT /patch_updates/1.xml
  def update
  end

end
