WebYaST::AdministratorEngine.routes.draw do
  resources :administrator, :only => [ :index, :update, :create ]
end
