
ActionController::Routing::Routes.draw do |map|
  map.resources :networks do |network|
    network.resources :permissions
  end
end
