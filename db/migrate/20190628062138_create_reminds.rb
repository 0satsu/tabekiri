class CreateReminds < ActiveRecord::Migration[5.2]
  def change
    create_table :reminds do |t|
      t.string :food
      t.date :date
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
