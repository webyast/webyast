  # load resources and populate database
class ResourceRegistration

  # start by cleaning Domain and Resource tables
  def self.init
    Resource.delete_all
    Domain.delete_all
  end
  
  # register a (.yaml) resource description

  def self.register file
    require 'yaml'
    
    $stderr.puts "ResourceRegistration.register #{file}"
    name = File.basename(file, ".*")
    begin
      resource = YAML.load(File.open(file))
    rescue Exception => e
      $stderr.puts "#{file} failed to load"
      raise
    end
    $stderr.puts "Found #{resource.inspect}"      
    # name: can override
    name = resource["name"] || name
      
    # domain: must be given
    domain = resource["domain"]
    raise "#{file} does not specify domain" unless domain

    # tags:, optional
    tags = resource["tags"] || ""
    tags = tags.split " "
    tags << name
    tags << domain
    
    # singular: is optional, defaults to false
    singular = resource["singular"] || false
      
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
      raise "Resource #{domain}::#{name} already exists"
    end
    r_resource = Resource.new
    r_resource.name = name
    r_resource.domain = r_domain
    r_resource.singular = singular
    r_resource.tag_list = tags
    r_resource.save

    $stderr.puts "Resource #{domain}::#{name} registered"
  end
  
  # register all resources below <topdir>/*/<subdir>/*.yaml
  def self.register_all topdir, subdir
    require 'find'
    $stderr.puts "Register all resources in #{topdir}/*/#{subdir}"
    Find.find(topdir) do |path|
      next unless path =~ %r{#{subdir}/(\w+)\.yaml$}
      $stderr.puts "  #{path} !"
      self.register path
    end
  end
  
  def self.route_all

    resources = Resource.find(:all)
    domains = Domain.find(:all)

    ActionController::Routing::Routes.draw do |map|
      # The priority is based upon order of creation: first created -> highest priority.
      #
      # YaST resource routing
      #
      # - prefix 'yast'
      # - resources are grouped in domains
      #

      domains.each do |ns|
	domain = ns.name
	map.with_options(:path_prefix => "yast") do |path|
	  path.namespace(domain) do |name|
	    $stderr.puts "Mapping #{domain}"
	    name.resources domain, :only => :index
	  end
	end
      end
      
      resources.each do |resource|
	domain = resource.domain.name
	prefix = "yast/#{domain}"
	
	#
	# doing .with_options(:domain => "...", :path_prefix => "...") assembles the controller domain without a slash :-(
	#															  
															  
	# create yast/<ns> routes
	map.with_options(:path_prefix => prefix) do |path|
	  # put the controller below <ns>
	  path.namespace(domain) do |yast|
	    $stderr.puts "Mapping #{domain}/#{resource.name}"
	    yast.resources resource.name
	  end
	end
      end # resources.each
      # /yast
      map.connect "/yast.:format", :controller => "yast", :action => "index"
    end # Routes.draw 
  
  end

end # class ResourceRegistration
