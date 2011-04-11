ActiveRecord::Schema.define do

  create_table :phone_numbers, :force => true do |t|
    t.column :number, :string, :length => 20, :null => false
    t.column :carrier_id, :integer, :default => nil
    t.column :owner_id, :integer, :default => nil
    t.column :country_code, :integer, :length => 5, :default => 1
    t.column :notes, :string, :default => nil
  end

  add_index :phone_numbers, :number, :unique => 'true', :name => 'uk_phone_numbers_number'

  create_table :carriers, :force => true do |t|
    t.column :name, :string, :length => 100
    t.column :email_domain, :string, :length => 100, :default => nil
    t.column :options, :string, :default => nil
  end
  add_index :carriers, :name, :unique => 'true', :name => 'uk_carriers_name'

end