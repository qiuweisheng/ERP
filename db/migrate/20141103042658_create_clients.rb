class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.integer :account_id
      t.string :name

      t.timestamps
    end
  end
end
