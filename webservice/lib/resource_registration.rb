# load resources and populate database
class ResourceRegistration
 
  @@resources = Hash.new
  def self.resources
    @@resources
  end
private
  def self.error msg
    if @@in_production
      log.error msg
      return
    else
      raise msg
    end
  end
public  
  #
  # reset registered resources
  # useful for testing
  #
  def self.reset
    @@resources = Hash.new
  end

  # register a (.yaml) resource description
  #
  # optionally the interface and controller can be passed
  # otherwise they are read from the yml file
  #
public  
  def self.reset
    @@resources = Hash.new
  end
  
  def self.register(file, interface = nil, controller = nil)
#    $stderr.puts "register #{file}"
    require 'yaml'
    @@in_production = (RAILS_ENV == "production")
    name = name || File.basename(file, ".*")
    begin
      resource = YAML.load(File.open(file)) || Hash.new
    rescue Exception => e
      $stderr.puts "#{file} failed to load"
      raise # re-raise
    end

    # interface: can override
    interface = resource['interface'] || interface
    error "#{file} does not specify interface" unless interface
    error "#{file}: interface is not a qualified name" unless interface =~ %r{((\w+)\.)+(\w+)}
   
    name = interface.split(".").pop
    
    # controller: must be given
    controller = resource['controller'] || controller
    error "#{file} does not specify controller" unless controller
#    error "#{file}: controller is not a path name" unless controller =~ %r{((\w+)/)+(\w+)}
    
    # singular: is optional, defaults to false
    singular = resource["singular"] || false

    error "#{file}: has non-plural interface #{interface} without being flagged as singular" if !singular and name != name.pluralize

    resources[interface] ||= Array.new
    resources[interface] << { :controller => controller, :singular => singular }
  end

  # register routes from a plugin
  #
  def self.register_plugin(plugin)
    res_path = File.join(plugin.directory, 'config')
#    $stderr.puts "checking #{res_path}"
    Dir.glob(File.join(res_path, 'routes.rb')).each do |route|
      basename = File.basename(plugin.directory)
      $stderr.puts "***Error: Plugin #{basename} does private routing, please remove #{basename}/config/routes.rb."
    end
    res_path = File.join(res_path, 'resources')
#    $stderr.puts "self.register_plugin #{res_path}"
    Dir.glob(File.join(res_path, '**/*.y*ml')).each do |descriptor|
#      $stderr.puts "checking #{descriptor}"
      next unless descriptor =~ %r{#{res_path}/((\w+)/)?(\w+)\.y(a)?ml$}
#      $stderr.puts "registering #{descriptor}"
      self.register(descriptor)
    end
  end

  # routes resources
  #
  def self.route resources
    return unless resources
    return if resources.empty?
    
    ActionController::Routing::Routes.draw do |map|
      map.root :controller => "resources", :action => "index"
      resources.each do |interface,implementations|
	
	qualifiers = interface.split "."
	name = qualifiers.pop
	
	implementations.each do |implementation|
	
	  # url and controller are closely coupled
	
	  # so we split the controller path and use every path element but the last one as routing namespaces
	  # the last one specifies the resource name and thus the controller name
	  #
	  namespaces = implementation[:controller].split "/"
	
	  # the .namespace call affects the URI _and_ the controller path (!)
	
	  toplevel = map
	  while namespaces.size > 1
	    toplevel.namespace(namespaces.shift) do |ns|
	      toplevel = ns
	    end
	  end
	
	  if implementation[:singular]
	    toplevel.resource name, :controller => namespaces.join("/"), :except => [ :new, :edit ]
	  else
	    toplevel.resources name, :except => [ :new, :edit ]
	  end
        end
      end
    end  
  end

end # class ResourceRegistration
