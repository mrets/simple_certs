class AddUserOrganizationId < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :organization
  end
end
