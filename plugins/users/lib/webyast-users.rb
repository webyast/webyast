module WebYaST
  class UsersEngine < Rails::Engine
    initializer "static assets" do |app|
      #Rails.error "initializing users module"
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
  end
end