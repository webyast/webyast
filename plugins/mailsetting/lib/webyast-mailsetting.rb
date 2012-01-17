module WebYaST
  class MailsettingEngine < Rails::Engine
    initializer "static assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end
  end
end
