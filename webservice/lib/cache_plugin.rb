class CachePlugin
  def self.find(what, container)
    models = []
    resources = Resource.find :all
    
    resources.each  do |resource|
      name = resource.href.split("/").last
      models << (name).classify if name==what || what==:all
    end
    
    models.each do |model|
      status = Object.const_get(model) rescue $!
      if status.class != NameError && status.respond_to?(:find)
	if status.respond_to?(:find_all) 
	  container[model] = "find_all"
	else 
	  container[model] = "find"
	end
      end
    end
    
    return container
  end
end
