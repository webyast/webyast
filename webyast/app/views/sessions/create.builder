# ugly workaround to avoid rendering result in Devise::SessionsController
if current_account.blank?
  xml << {:login => "denied"}.to_xml
else
  xml << {:login => "granted", :auth_token => { :value => current_account.authentication_token, :expires => current_account.token_expires_at} }.to_xml
end
