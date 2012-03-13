WebYaST::SoftwareEngine.routes.draw do
  resources :patches do
    collection do
      get :show_summary
      get :start_install_all
      get :license
      get :load_filtered
    end
  end
  resources :repositories
end
