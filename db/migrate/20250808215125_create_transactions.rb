class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.string :request_uuid, limit: 36, null: false
      t.integer :request_user_id, null: false
      t.datetime :initiated_at, null: false
      t.datetime :recorded_at, null: false
      t.string :resource, null: false
      t.string :action, null: false
      t.boolean :completed, null: false
      t.integer :record_id
      t.string :old_state
      t.string :new_state
    end
  end
end