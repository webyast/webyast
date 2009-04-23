class ResourceController < ApplicationController

  def index
#    $stderr.puts "Params #{params.inspect}"
    resources = Array.new
    
    if params[:tags]
      resources = Resource.find_tagged_with(params[:tags], :match_all => true)
    elsif params[:name]
      resources = Resource.find(:all, :conditions => ["name = ?", params[:name]])
    elsif params[:domain]
      domain = Domain.find(:first, :conditions => ["name = ?", params[:domain]])
      resources = Resource.find(:all, :conditions => ["domain_id = ?", domain]) if domain
    else
      resources = Resource.find(:all)
    end
    @node = "Yast"
    @resources = Array.new
    routes = ActionController::Routing::Routes.routes
    # respond_to do |format|
    #  format.html { ... }
    #  format.xml { ... }
    # end
    #
    # -> index.erb.<format>
    resources.each do |res|
      n = res.name
      ns = res.domain
      c = "#{ns}/#{n}"
      route = routes.find { |r| r.requirements[:controller] == c and r.requirements[:action] == "index" }
      if route
	@resources << [ c, route.requirements ]
      else
	$stderr.puts "No route for #{c}"
      end
    end
  end
end
