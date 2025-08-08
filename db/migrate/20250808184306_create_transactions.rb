class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      # Event identification
      t.string :event_type, null: false
      t.string :transaction_id, null: false
      
      # Actor information
      t.references :user, foreign_key: true
      t.references :organization, foreign_key: true
      
      # Primary resource references
      t.references :certificate, foreign_key: true
      t.references :certificate_quantity, foreign_key: true
      t.references :generation, foreign_key: true
      t.references :account, foreign_key: true
      
      # Secondary resource references (for transfers, splits)
      t.bigint :target_account_id
      t.bigint :target_organization_id
      t.bigint :new_certificate_quantity_id
      
      # Quantity tracking
      t.decimal :quantity_before
      t.decimal :quantity_after
      t.decimal :quantity_changed
      
      # State tracking
      t.string :status_before
      t.string :status_after
      
      # Additional metadata
      t.json :metadata
      t.text :error_message
      t.boolean :success, null: false, default: false
      
      # Request tracking
      t.string :request_id
      t.string :ip_address
      
      t.timestamps
      
      # Indexes for performance (references already create indexes)
      t.index :transaction_id, unique: true
      t.index :event_type
      t.index :created_at
      t.index [:event_type, :created_at]
      t.index :request_id
    end
    
    # Add foreign key constraints for secondary references
    add_foreign_key :transactions, :accounts, column: :target_account_id
    add_foreign_key :transactions, :organizations, column: :target_organization_id
    add_foreign_key :transactions, :certificate_quantities, column: :new_certificate_quantity_id
    
    # Add check constraint to ensure append-only (no updates allowed)
    # Note: SQLite doesn't support check constraints via Rails migrations,
    # but we'll enforce this at the application level
  end
end