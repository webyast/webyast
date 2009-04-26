# load resources and populate database
class ResourceRegistration

  # start by cleaning Domain and Resource tables
  def self.init
    Resource.delete_all if Resource.table_exists?
    Domain.delete_all if Domain.table_exists?
  end
  
  # register a (.yaml) resource description
  #
  # optionally the name and domain can be passed
  # otherwise they are read from the yml file
  def self.register(file, name = nil, domain = nil)
    $stderr.puts "register #{file}"
    require 'yaml'
    in_production = (ENV["RAILS_ENV"] == "production")
    name = name || File.basename(file, ".*")
    begin
      resource = YAML.load(File.open(file)) || Hash.new
    rescue Exception => e
      $stderr.puts "#{file} failed to load"
      raise
    end

    # name: can override
    name = resource['name'] || name
      
    # domain: must be given
    d = resource['domain'] 
    if d
      if domain and domain != d
	error = "#{file} has inconsistent domain to parent dir"
	if in_production
	  logger.error error
	  return
	else
	  raise error
	end
      end
      domain = d unless domain
    end
    
    unless domain
      error = "#{file} does not specify domain" 
      if in_production
	log.error
	return
      else
	raise error
      end
    end
    
    # tags:, optional
    tags = resource["tags"] || ""
    tags = tags.split " "
    tags << name
    tags << domain
    
    # singular: is optional, defaults to false
    singular = resource["singular"] || false
      
    if !singular and name != name.pluralize
      error = "#{file}: has non-plural name without being flagged as singular"
      if in_production
	log.error error
	return
      else
	raise error
      end
    end
    
    # -------- database, r_ == record

    # Create/Find domain
    r_domain = Domain.find_by_name(domain)
    unless r_domain
      r_domain = Domain.new
      r_domain.name = domain
      r_domain.save
    end
      
    # Create/Find resource
    
    # should be:    r_resource = Resource.find_by_name_and_domain(name, r_domain)
    r_resource = Resource.find(:first, :conditions => ["name = ? and domain_id = ?", name, r_domain])
    if r_resource
      error = "Resource #{domain}::#{name} already exists"
      if in_production
	log.error error
	return
      else
	raise error
      end
    end
    r_resource = Resource.new
    r_resource.name = name
    r_resource.domain = r_domain
    r_resource.singular = singular
    r_resource.tag_list = tags
    r_resource.save

  end

  # register routes from a plugin
  def self.register_plugin(plugin)
    res_path = File.join(plugin.directory, 'config', 'resources')
    Dir.glob(File.join(res_path, '**/*.yml')).each do |descriptor|
      next unless descriptor =~ %r{#{res_path}/((\w+)/)?(\w+)\.yml$}
      self.register(descriptor, $3, $2)
    end
  end

  # routes all registered plugins
  def self.route_all
    if not Resource.table_exists? or
       not Domain.table_exists?
      Rails.logger.debug "routes not ready because db:migrate not done"
      return
    end
    
    prefix = "yast"
    
    resources = Resource.find(:all)
    domains = Domain.find(:all)

    ActionController::Routing::Routes.draw do |map|
      map.resources prefix, :controller => "resource", :only => :index
      resources.each do |resource|

        # make the old routes still valid
        if resource.singular?
          map.resource resource.name
        else
          map.resources resource.name
        end
        
	domain = resource.domain
	
	# doing .with_options(:domain => "...", :path_prefix => "...") assembles the controller domain without a slash :-(
	#
        #map.with_options(:path_prefix => "#{prefix}/#{domain}") do |path|
        map.with_options(:path_prefix => "#{prefix}") do |path|
	  # put the controller below <ns>
	  path.namespace(domain.name) do |yast|
	    yast.resources resource.name
	  end
	end
      end # resources.each
      
    end # Routes.draw 
  
  end

end # class ResourceRegistration
