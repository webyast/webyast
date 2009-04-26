ActionController::Routing::Routes.draw do |map|

  map.resources :patch_updates
  map.connect "/patch_updates/:id", :controller => 'patch_updates', :action => 'install'

end
