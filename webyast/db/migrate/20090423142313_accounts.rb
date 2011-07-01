class Accounts < ActiveRecord::Migration
  def self.up
    create_table "accounts", :force => true do |t|
      t.column :login,                     :string
      t.column :salt,                      :string
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime      
    end

  end

  def self.down
    drop_table "accounts"
  end
end
