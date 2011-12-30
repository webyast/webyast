WebYaST::SoftwareEngine.routes.draw do
  resources :patches do
    collection do
      get :show_summary
      get :load_filtered
    end
  end
  resources :repositories
end
