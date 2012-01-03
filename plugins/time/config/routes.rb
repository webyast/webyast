WebYaST::TimeEngine.routes.draw do
  resources :time do
    collection do
      get :timezones_for_region
    end
  end
end
