WebYaST::TimeEngine.routes.draw do
  resources :time do
    collection do
      get :timezones
    end
  end
end
