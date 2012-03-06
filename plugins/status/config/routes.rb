WebYaST::StatusEngine.routes.draw do
  resources :status do
    collection do
      get :show_summary
      get :edit, :as => :html
    end
  end
  
  resources :metrics
end
