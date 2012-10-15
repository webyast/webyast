WebYaST::SystemEngine.routes.draw do
  resource :system, :only => [:show, :update, :create], :controller => "system" do
    collection do
      put "reboot"
      put "shutdown"
    end
  end
end
