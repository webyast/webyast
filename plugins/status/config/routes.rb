WebYaST::StatusEngine.routes.draw do
  resources :status do
    collection do
      get :show_summary
      get :edit
    end
  end
  
  resources :metrics, :only => [:index, :show]
  resources :logs, :only => [:index, :show]
  resources :graphs, :only => [:index, :show, :update]
end
