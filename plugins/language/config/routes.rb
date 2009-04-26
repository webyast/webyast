ActionController::Routing::Routes.draw do |map|

  map.resource :language, :controller => 'language'
  map.connect "/language/:id", :controller => 'language', :action => 'singlevalue'
  map.connect "/language/:id.xml", :controller => 'language', :action => 'singlevalue', :format =>'xml'
  map.connect "/language/:id.html", :controller => 'language', :action => 'singlevalue', :format =>'html'
  map.connect "/language/:id.json", :controller => 'language', :action => 'singlevalue', :format =>'json'

end
