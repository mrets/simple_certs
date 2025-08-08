class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :record_type, null: false
      t.integer :record_id, null: false
      t.string :event, null: false
      t.text :changeset

      t.timestamps
    end
  end
end
