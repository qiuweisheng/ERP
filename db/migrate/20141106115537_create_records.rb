class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.integer :record_type
      t.references :origin, index: true
      t.references :product, index: true
      t.decimal :weight
      t.integer :count, default: 0
      t.references :user, index: true
      t.references :client, index: true, polymorphic: true

      t.timestamps
    end
  end
end
