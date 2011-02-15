class DataCachesController < ApplicationController
  # GET /data_caches
  # GET /data_caches.xml
  def index
    @data_caches = DataCache.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @data_caches }
    end
  end

  # GET /data_caches/1
  # GET /data_caches/1.xml
  def show
    @data_cache = DataCache.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @data_cache }
    end
  end

  # GET /data_caches/new
  # GET /data_caches/new.xml
  def new
    @data_cache = DataCache.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @data_cache }
    end
  end

  # GET /data_caches/1/edit
  def edit
    @data_cache = DataCache.find(params[:id])
  end

  # POST /data_caches
  # POST /data_caches.xml
  def create
    @data_cache = DataCache.new(params[:data_cache])

    respond_to do |format|
      if @data_cache.save
        format.html { redirect_to(@data_cache, :notice => 'DataCache was successfully created.') }
        format.xml  { render :xml => @data_cache, :status => :created, :location => @data_cache }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @data_cache.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /data_caches/1
  # PUT /data_caches/1.xml
  def update
    @data_cache = DataCache.find(params[:id])

    respond_to do |format|
      if @data_cache.update_attributes(params[:data_cache])
        format.html { redirect_to(@data_cache, :notice => 'DataCache was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @data_cache.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /data_caches/1
  # DELETE /data_caches/1.xml
  def destroy
    @data_cache = DataCache.find(params[:id])
    @data_cache.destroy

    respond_to do |format|
      format.html { redirect_to(data_caches_url) }
      format.xml  { head :ok }
    end
  end
end
