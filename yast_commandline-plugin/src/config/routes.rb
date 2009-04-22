ActionController::Routing::Routes.draw do |map|

  map.resources :yast_modules
  map.connect "/yast_modules/:action/:id", :controller => 'yast_modules', :action => 'run'
  map.connect "/yast_modules/:id", :controller => 'yast_modules', :action => 'run'
  map.connect "/yast_modules/:id.xml", :controller => 'yast_modules', :action => 'run', :format =>'xml'
  map.connect "/yast_modules/:id.html", :controller => 'yast_modules', :action => 'run', :format =>'html'
  map.connect "/yast_modules/:id.json", :controller => 'yast_modules', :action => 'run', :format =>'json'

end
