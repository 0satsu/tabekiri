class AddLastMessageeToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :last_message, :text
  end
end
