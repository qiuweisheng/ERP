class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :account_id
      t.string :name
      t.string :password_digest
      t.string :type

      t.timestamps
    end
  end
end
