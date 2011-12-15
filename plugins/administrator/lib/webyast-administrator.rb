module WebYaST
  class AdministratorEngine < Rails::Engine
    initializer "static assets" do |app|
      #Rails.error "initializing administrator module"
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
  end
end
