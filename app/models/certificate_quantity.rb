class CertificateQuantity < ApplicationRecord
  belongs_to :certificate
  belongs_to :account
  belongs_to :to_organization, class_name: "Organization", foreign_key: "to_organization_id", optional: true

  def split(quantity)
    split_values = {certificate: certificate, account: account, quantity: self.quantity - quantity, status: "active"}
    split_record = self.class.create(split_values)
    {
      original_record: mod_state(quantity: quantity),
      split_record: {id: split_record.id, old_state: {}, new_state: split_values}
    }
  end

  def retire
    mod_state(status: "retired")
  end

  def transfer(account_id, organization_id)
    if account_id then mod_state({account_id: account_id})
    elsif organization_id then mod_state({status: "intransit", to_organization_id: organization_id})
    end
  end

  def cancel_transfer
    mod_state(status: "active", to_organization: nil)
  end

  def accept_transfer(account_id)
    mod_state(status: "active", to_organization: nil, account: Account.find(account_id))
  end

  private

  def mod_state(param_hash)
    old_state = {}
    param_hash.each do |key, value|
      old_state[key] = self.attributes[key.to_s]
    end
    update(param_hash)
    return {old_state: old_state, new_state: param_hash}
  end
end
