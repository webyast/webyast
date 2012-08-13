WebYaST::LdapEngine.routes.draw do
  get 'ldap/fetch_dn', :controller => "ldap"
  resources :ldap
end
