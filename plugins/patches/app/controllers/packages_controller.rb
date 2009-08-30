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

  public

  def compare_lists(packages)
    vendor_packages = Hash.new
    # yml datei auslesen: ["packages"] => ["yast-core", "ruby-dbus", ...]
    package_list = Array.new
    package_list << ["yast2-users", "3ddiag", "foo"]

    package_list.each {|pk_name|
      packages.each {|p|
        # package installed?
        if p.name == pk_name
          # store version and name
          vendor_packages["package"] = {:name => "#{p.name}", :version => "#{p.version}"}
        end
      }
      unless vendor_packages.has_key? pk_name
        vendor_packages["package"] = {"#{pk_name}" => "not installed"}
      end
    }
    # puts vendor_packages.inspect
    vendor_packages
  end

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
