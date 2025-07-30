class AddDefaultAccountToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_reference :organizations, :default_account
  end
end
