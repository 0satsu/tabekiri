class AddBeforeToRemind < ActiveRecord::Migration[5.2]
  def change
    add_column :reminds, :before, :integer
  end
end
