class RepositoriesController < ApplicationController

  before_filter :login_required

#  TODO: implement caching - PackageKit query is quite slow

  public

  # GET /repositories.xml
  def index
    permission_check "org.opensuse.yast.system.repositories.read"

    @repos = Repository.find(:all)
  end

  # GET /repositories/my_repo.xml
  def show
    permission_check "org.opensuse.yast.system.repositories.read"

    repos = Repository.find(params[:id])
    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Repository #{params[:id]} was not found.") and return
    end

    @repo = repos.first
  end

  # GET /repositories/my_repo.xml
  def update
    permission_check "org.opensuse.yast.system.repositories.write"

    repos = Repository.find(params[:id])

    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Repository '#{params[:id]}' was not found.") and return
    end

    @repo = repos.first

    unless @repo.save
      render ErrorResult.error(404, 2, "packagekit error") and return
    end

    render :show
  end

  # POST /repositories/
  def create
    permission_check "org.opensuse.yast.system.repositories.write"

    @repo = Repository.new(params[:repositories][:id].to_s,
      params[:repositories][:name].to_s, params[:repositories][:enabled])

    unless @repo.save
      render ErrorResult.error(404, 2, "Cannot save repository '#{@repo.id}'") and return
    end
    render :show
  end

  def destroy
    permission_check "org.opensuse.yast.system.repositories.write"

    repos = Repository.find(params[:id])

    if repos.nil? || repos.size.zero?
      Rails.logger.error "Repository #{params[:id]} was not found."
      render ErrorResult.error(404, 1, "Repository '#{params[:id]}' not found.") and return
    end

    @repo = repos.first

    unless @repo.destroy
      render ErrorResult.error(404, 2, "packagekit error") and return
    end

    render :show
  end

end