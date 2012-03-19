module WebYaST
  class StatusEngine < Rails::Engine
    initializer "static assets" do |app|
      #Rails.error "initializing status module"
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
  end
end
