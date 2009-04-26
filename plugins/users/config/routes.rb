
ActionController::Routing::Routes.draw do |map|
  map.resources :users do |users|
    users.resources :permissions
  end
end
