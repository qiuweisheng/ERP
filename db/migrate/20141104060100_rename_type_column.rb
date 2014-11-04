class RenameTypeColumn < ActiveRecord::Migration
  def change
    rename_column :users, :type, :account_type
  end
end
