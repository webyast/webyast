  # load resources and populate database
class ResourceRegistration

  # start by cleaning Domain and Resource tables
  def self.init
    Resource.delete_all
    Domain.delete_all
  end
  
  # register a (.yaml) resource description

  def self.register file, name = nil, domain = nil
    require 'yaml'
    in_production = (ENV["RAILS_ENV"] == "production")
    name = name || File.basename(file, ".*")
    begin
      resource = YAML.load(File.open(file))
    rescue Exception => e
      $stderr.puts "#{file} failed to load"
      raise
    end

    # name: can override
    name = resource["name"] || name
      
    # domain: must be given
    d = resource["domain"] 
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
	raise 
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
  
  # register all resources below <topdir>/*/<subdir>/*.yaml
  def self.register_all topdir, subdir
    require 'find'
#    $stderr.puts "Register all resources in #{topdir}/*/#{subdir}"
    Find.find(topdir) do |path|
      next unless path =~ %r{#{subdir}/((\w+)/)?(\w+)\.ya?ml$}
#      $stderr.puts "  #{path}, (domain #{$2}, name #{$3}) !"
      self.register path, $3, $2
    end
  end
  
  def self.route_all

    prefix = "yast"
    
    resources = Resource.find(:all)
    domains = Domain.find(:all)

    ActionController::Routing::Routes.draw do |map|

      map.resources prefix, :controller => "resource", :only => :index

      resources.each do |resource|
	domain = resource.domain
	
	#
	# doing .with_options(:domain => "...", :path_prefix => "...") assembles the controller domain without a slash :-(
	#															  

	map.with_options(:path_prefix => "#{prefix}/#{domain}") do |path|
	  # put the controller below <ns>
	  path.namespace(domain.name) do |yast|
	    yast.resources resource.name
	  end
	end
      end # resources.each
      
    end # Routes.draw 
  
  end

end # class ResourceRegistration
