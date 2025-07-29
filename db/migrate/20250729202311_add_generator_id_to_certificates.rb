class AddGeneratorIdToCertificates < ActiveRecord::Migration[8.0]
  def change
    add_reference :certificates, :generator
  end
end
