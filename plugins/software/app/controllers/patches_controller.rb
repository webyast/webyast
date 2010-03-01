require 'singleton'

class PatchesController < ApplicationController

   before_filter :login_required

   # always check permissions and cache expiration
   # even if the result is already created and cached
   before_filter :check_read_permissions, :only => [:index, :show]
   before_filter :check_cache_status, :only => :index

   # cache 'index' method result
   caches_action :index

  private

  def check_read_permissions
    permission_check "org.opensuse.yast.system.patches.read"
  end

  # check whether the cached result is still valid
  def check_cache_status
    cache_timestamp = Rails.cache.read('patches:timestamp')

    if cache_timestamp.nil?
	# this is the first run, the cache is not initialized yet, just return
	Rails.cache.write('patches:timestamp', Time.now)
	return
    # the cache expires after 5 minutes, repository metadata
    # or RPM database update invalidates the cache immediately
    # (new patches might be applicable)
    elsif cache_timestamp < 15.minutes.ago || cache_timestamp < Patch.mtime
	logger.debug "#### Patch cache expired"
	expire_action :action => :index, :format => params["format"]
	Rails.cache.write('patches:timestamp', Time.now)
    end
  end

  public

  # GET /patch_updates
  # GET /patch_updates.xml
  def index
    # note: permission check was performed in :before_filter
    bgr = params['background']
    Rails.logger.info "Reading patches in background" if bgr

    @patches = Patch.find(:available, {:background => bgr})

    respond_to do |format|
      format.xml { render  :xml => @patches.to_xml( :root => "patches", :dasherize => false ) }
      format.json { render :json => @patches.to_json( :root => "patches", :dasherize => false ) }
    end

    # do not cache the background progress status
    # (expire the cache in the next request)
    if bgr && @patches.first.class == BackgroundStatus
      Rails.cache.write('patches:timestamp', Time.at(0))
    end
  end

  # GET /patch_updates/1
  # GET /patch_updates/1.xml
  def show
    @patch_update = Patch.find(params[:id])
    if @patch_update.nil?
      logger.error "Patch: #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:id]} not found.") and return
    end
  end

  # PUT /patch_updates/1
  # PUT /patch_updates/1.xml
  def update
    permission_check "org.opensuse.yast.system.patches.install"
    @patch_update = Patch.find(params[:id])
    if @patch_update.nil?
      logger.error "Patch: #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:id]} not found.") and return
    end
    unless @patch_update.install
      render ErrorResult.error(404, 2, "packagekit error") and return
    end
    render :show
  end

  # POST /patch_updates/
  def create
    permission_check "org.opensuse.yast.system.patches.install"
    @patch_update = Patch.find(params[:patches][:resolvable_id].to_s)
    if @patch_update.nil?
      logger.error "Patch: #{params[:patches][:resolvable_id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:patches][:resolvable_id]} not found.") and return
    end
    unless Patch.install @patch_update
      render ErrorResult.error(404, 2, "packagekit error") and return
    end
    render :show
  end


end
