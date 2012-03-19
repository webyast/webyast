module WebYaST
  class ServicesEngine < Rails::Engine
    initializer "static assets" do |app|
      #Rails.error "initializing services module"
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
  end
end
