WebYaST::MailsettingEngine.routes.draw do
  resource :mailsetting, :controller => :mailsetting do
    post 'send_test_mail'
  end
end
