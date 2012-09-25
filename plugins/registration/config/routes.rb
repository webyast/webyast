WebYaST::RegistrationEngine.routes.draw do
  resources :registration, :only => [:index, :show, :create, :update] do
    collection do
      # TODO FIXME: ??? replace this by parameters, e.g. index.html?reregister=true
      #   POST register.html?reregister=true
      get 'skip'
      get 'register'
      get 'reregister'
      get 'reregisterupdate'

      get 'configuration'
      put 'configuration' => "registration#configuration_update"
    end
  end
end
