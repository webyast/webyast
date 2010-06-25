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
    # or RPM database update invalidates the cache immeditely
    # (new patches might be applicable)
    elsif cache_timestamp < 5.minutes.ago || cache_timestamp < Patch.mtime
	logger.debug "#### Patch cache expired"
	expire_action :action => :index, :format => params["format"]
	Rails.cache.write('patches:timestamp', Time.now)
    end
  end

  def collect_done_patches
    done = []

    BackgroundManager.instance.done.each do |k,v|
      if k.match(/^packagekit_install_(.*)/)
        patch_id = $1
        if BackgroundManager.instance.process_finished? k
          Rails.logger.debug "Patch installation request #{patch_id} is done"
          ret = BackgroundManager.instance.get_value k

          # check for exception
          if ret.is_a? StandardError
            raise ret
          end

          # e.g.: 'suse-build-key;1.0-907.30;noarch;@System'
          attrs = patch_id.split(';')

          done << Patch.new(:resolvable_id => attrs[1],
                           :name => attrs[0],
                           :arch => attrs[2],
                           :repo => attrs[3],
                           :installing => false,
                           :installed => ret)
        end
      end
    end

    return done
  end

  public

  # GET /patch_updates
  # GET /patch_updates.xml
  def index
    # note: permission check was performed in :before_filter
    @patches = Patch.find(:available)

    results = collect_done_patches
    # invalidate cache when patch installation is running
    if @patches.find {|p| p.installing == true} || !results.empty?
      Rails.cache.write('patches:timestamp', Time.at(0))
    end

    @patches += results

    logger.debug "Running requests: #{BackgroundManager.instance.running.inspect}"
    logger.debug "Done requests: #{BackgroundManager.instance.done.inspect}"
    respond_to do |format|
      format.xml { render  :xml => @patches.to_xml( :root => "patches", :dasherize => false ) }
      format.json { render :json => @patches.to_json( :root => "patches", :dasherize => false ) }
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

#    bgr = params['background']
#    bgr = true
#    Rails.logger.info "Installing patch #{params[:patches][:resolvable_id]} in background" if bgr

    #Patch for Bug 560701 - [build 24.1] webYaST appears to crash after installing webclient patch
    #Packagekit returns empty string if the patch is allready installed.
    if @patch_update.is_a?(Array) && @patch_update.empty?
       logger.error "Patch is allready installed or not found #{@patch_update.inspect}"
       render ErrorResult.error(404, 1, "Patch is not required.") and return
    end

    if @patch_update.nil?
      logger.error "Patch: #{params[:patches][:resolvable_id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:patches][:resolvable_id]} not found.") and return
    end

    res = @patch_update.install(true)

    if (res.is_a? BackgroundStatus)
      logger.debug "received background status: #{res.inspect}"
      respond_to do |format|
        format.xml { render  :xml => res.to_xml( :root => "status", :dasherize => false ) }
        format.json { render :json => res.to_json( :root => "status", :dasherize => false ) }
      end

      return
    end

#    unless error
#      render ErrorResult.error(404, 2, "packagekit error") and return
#    end
    render :show
  end


end
