WebYaST::NetworkEngine.routes.draw do
  match "/network/iface" => "network#iface", :as => :ajax
  match "/network/partial" => "network#partial", :as => :partial
end
