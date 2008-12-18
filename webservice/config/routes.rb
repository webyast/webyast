ActionController::Routing::Routes.draw do |map|

  map.resources :sysconfigs
  map.resource :session

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  map.resource :config, :controller => 'config_ntp', :path_prefix => "/services/ntp"
  map.connect "/services/ntp/config/:id", :controller => 'config_ntp', :action => 'singleValue'
  map.connect "/services/ntp/config/:id.xml", :controller => 'config_ntp', :action => 'singleValue', :format =>'xml'
  map.connect "/services/ntp/config/:id.html", :controller => 'config_ntp', :action => 'singleValue', :format =>'html'
  map.connect "/services/ntp/config/:id.json", :controller => 'config_ntp', :action => 'singleValue', :format =>'json'

  map.namespace :services do |service|
      service.resource :dummy
  end

  map.resources :services do |service|
     service.resources :commands
  end

  map.resource :systemtime, :controller => 'systemtime'
  map.connect "/systemtime/:id", :controller => 'systemtime', :action => 'singleValue'
  map.connect "/systemtime/:id.xml", :controller => 'systemtime', :action => 'singleValue', :format =>'xml'
  map.connect "/systemtime/:id.html", :controller => 'systemtime', :action => 'singleValue', :format =>'html'
  map.connect "/systemtime/:id.json", :controller => 'systemtime', :action => 'singleValue', :format =>'json'

  map.resource :language, :controller => 'language'
  map.connect "/language/:id", :controller => 'language', :action => 'singleValue'
  map.connect "/language/:id.xml", :controller => 'language', :action => 'singleValue', :format =>'xml'
  map.connect "/language/:id.html", :controller => 'language', :action => 'singleValue', :format =>'html'
  map.connect "/language/:id.json", :controller => 'language', :action => 'singleValue', :format =>'json'

  map.resources :users, :member => { :exportssh => :get }
  map.resources :users, :controller => 'users'

  #required by ActiveResource
  map.connect "/users/:users_id/update.xml", :controller => 'users', :action => 'update', :format =>'xml'
  map.connect "/users/:users_id/update.json", :controller => 'users', :action => 'update', :format =>'json'
  map.connect "/users/new/create.xml", :controller => 'users', :action => 'create', :format =>'xml'
  map.connect "/users/new/create.json", :controller => 'users', :action => 'create', :format =>'json'

  map.connect "/users/:users_id/exportssh", :controller => 'users', :action => 'exportssh'
  map.connect "/users/:users_id/:id", :controller => 'users', :action => 'singleValue'
  map.connect "/users/:users_id/:id.xml", :controller => 'users', :action => 'singleValue', :format =>'xml'
  map.connect "/users/:users_id/:id.html", :controller => 'users', :action => 'singleValue', :format =>'html'
  map.connect "/users/:users_id/:id.json", :controller => 'users', :action => 'singleValue', :format =>'json'

  map.resources :patch_updates
  map.connect "/patch_updates/:id", :controller => 'patch_updates', :action => 'install'

  map.resources :yast_modules
  map.connect "/yast_modules/:action/:id", :controller => 'yast_modules', :action => 'run'
  map.connect "/yast_modules/:id", :controller => 'yast_modules', :action => 'run'
  map.connect "/yast_modules/:id.xml", :controller => 'yast_modules', :action => 'run', :format =>'xml'
  map.connect "/yast_modules/:id.html", :controller => 'yast_modules', :action => 'run', :format =>'html'
  map.connect "/yast_modules/:id.json", :controller => 'yast_modules', :action => 'run', :format =>'json'

  map.connect "/checkpermission/:id", :controller => 'check_permission', :action => 'show'
  map.connect "/checkpermission/:id.xml", :controller => 'check_permission', :action => 'show', :format =>'xml'
  map.connect "/checkpermission/:id.html", :controller => 'check_permission', :action => 'show', :format =>'html'
  map.connect "/checkpermission/:id.json", :controller => 'check_permission', :action => 'show', :format =>'json'

  map.login '/login', :controller => 'sessions', :action => 'new'
  map.login '/login.xml', :controller => 'sessions', :action => 'create', :format =>'xml'
  map.login '/login.html', :controller => 'sessions', :action => 'create', :format =>'html'
  map.login '/login.json', :controller => 'sessions', :action => 'create', :format =>'json'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.logout '/logout.xml', :controller => 'sessions', :action => 'destroy', :format =>'xml'
  map.logout '/logout.json', :controller => 'sessions', :action => 'destroy', :format =>'json'
  map.logout '/logout.html', :controller => 'sessions', :action => 'destroy', :format =>'html'

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action.:format'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.resource :yast, :controller => 'yast'

  map.connect "/.xml", :controller => 'yast', :action => 'index', :format =>'xml'
  map.connect "/.json", :controller => 'yast', :action => 'index', :format =>'json'
  map.root :controller => "yast"
end
