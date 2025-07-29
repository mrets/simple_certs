class AddAccountIdToCertificateQuantities < ActiveRecord::Migration[8.0]
  def change
    add_reference :certificate_quantities, :account
  end
end
