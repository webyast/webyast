WebYaST::AdministratorEngine.routes.draw do
  resource :administrator, :only => [ :index, :update, :create ], :controller => :administrator
end
