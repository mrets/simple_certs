class AddBaseModels < ActiveRecord::Migration[8.0]
  def change
    create_table :generators do |t|
      t.string :name
      t.string :ext_id
    end

    create_table :generations do |t|
      t.date :start_date
      t.date :end_date
      t.integer :quantity
      t.references :generator
    end

    create_table :certificates do |t|
      t.string :sn_base
      t.integer :quantity
      t.references :generation_entry
    end

    create_table :certificate_quantities do |t|
      t.integer :sn_start
      t.integer :quantity
      t.references :certificate
    end

    create_table :account do |t|
      t.string :name
      t.references :organization
    end

    create_table :organizations do |t|
      t.string :name
    end
  end
end
