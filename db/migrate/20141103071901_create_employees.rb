class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.integer :serial_number
      t.string :name
      t.references :department, index: true

      t.timestamps
    end
  end
end
