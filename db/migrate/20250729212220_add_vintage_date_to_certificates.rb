class AddVintageDateToCertificates < ActiveRecord::Migration[8.0]
  def change
    add_column :certificates, :vintage_date, :date
  end
end
