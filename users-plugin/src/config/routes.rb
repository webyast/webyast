ActionController::Routing::Routes.draw do |map|

  map.resources :users do |users|
    users.resources :permissions
  end

  map.resources :users, :member => { :exportssh => :get }
  map.resources :users, :controller => 'users'

  #required by ActiveResource
  map.connect "/users/:users_id/update.xml", :controller => 'users', :action => 'update', :format =>'xml'
  map.connect "/users/:users_id/update.json", :controller => 'users', :action => 'update', :format =>'json'
  map.connect "/users/new/create.xml", :controller => 'users', :action => 'create', :format =>'xml'
  map.connect "/users/new/create.json", :controller => 'users', :action => 'create', :format =>'json'

  map.connect "/users/:users_id/exportssh", :controller => 'users', :action => 'exportssh'
  map.connect "/users/:users_id/:id", :controller => 'users', :action => 'singlevalue'
  map.connect "/users/:users_id/:id.xml", :controller => 'users', :action => 'singlevalue', :format =>'xml'
  map.connect "/users/:users_id/:id.html", :controller => 'users', :action => 'singlevalue', :format =>'html'
  map.connect "/users/:users_id/:id.json", :controller => 'users', :action => 'singlevalue', :format =>'json'

end
