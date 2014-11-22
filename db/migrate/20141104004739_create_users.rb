class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :serial_number
      t.string :name
      t.string :password_digest
      t.integer :permission
      t.integer :state, default: 0

      t.timestamps
    end
  end
end
