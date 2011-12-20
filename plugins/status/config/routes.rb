WebYaST::StatusEngine.routes.draw do
  resources :status do
    collection do
      get :show_summary
    end
  end
  resources :metrics
end
