class AddStatusChangedAtToCertificateQuantity < ActiveRecord::Migration[8.0]
  def change
    change_table :certificate_quantities do |t|
      t.datetime :status_changed_at
    end
  end
end
