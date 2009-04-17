ActionController::Routing::Routes.draw do |map|

  map.resource :systemtime, :controller => 'systemtime'
  map.connect "/systemtime/:id", :controller => 'systemtime', :action => 'singlevalue'
  map.connect "/systemtime/:id.xml", :controller => 'systemtime', :action => 'singlevalue', :format =>'xml'
  map.connect "/systemtime/:id.html", :controller => 'systemtime', :action => 'singlevalue', :format =>'html'
  map.connect "/systemtime/:id.json", :controller => 'systemtime', :action => 'singlevalue', :format =>'json'

end
