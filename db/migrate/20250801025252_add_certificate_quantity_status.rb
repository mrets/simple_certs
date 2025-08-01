class AddCertificateQuantityStatus < ActiveRecord::Migration[8.0]
  def change
    add_column :certificate_quantities, :status, :string
    add_reference :certificate_quantities, :to_organization
  end
end
