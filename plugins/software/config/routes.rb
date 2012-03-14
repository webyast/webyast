WebYaST::SoftwareEngine.routes.draw do
  resources :patches do
    collection do
      get :show_summary
      get :start_install_all
      get :license
      get :message
      get :load_filtered
    end
  end
  resources :repositories
end
