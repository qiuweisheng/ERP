class CreateProfiles < ActiveRecord::Migration
  def change
    create_table :profiles do |t|
      t.string :key
      t.string :value
      t.string :value_type

      t.timestamps
    end
  end
end
