require 'devise'

$: << File.expand_path("..", __FILE__)

require 'devise_unix2_chkpwd_authenticatable/model'
require 'devise_unix2_chkpwd_authenticatable/strategy'
require 'devise_unix2_chkpwd_authenticatable/routes'
Devise.add_module(:unix2_chkpwd_authenticatable, :strategy => true, :model => "devise_unix2_chkpwd_authenticatable/model", :route => true)
