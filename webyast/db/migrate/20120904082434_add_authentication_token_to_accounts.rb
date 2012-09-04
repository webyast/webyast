class AddAuthenticationTokenToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :authentication_token, :string
    add_index :accounts, :authentication_token
  end
end
