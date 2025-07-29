class RenameCertificateGenerationEntryId < ActiveRecord::Migration[8.0]
  def change
    rename_column :certificates, :generation_entry_id, :generation_id
  end
end
