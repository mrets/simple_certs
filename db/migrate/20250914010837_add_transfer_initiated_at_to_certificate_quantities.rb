class AddTransferInitiatedAtToCertificateQuantities < ActiveRecord::Migration[8.0]
  def change
    add_column :certificate_quantities, :transfer_initiated_at, :datetime
    add_index :certificate_quantities, :transfer_initiated_at
  end
end
