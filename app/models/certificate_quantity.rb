class CertificateQuantity < ApplicationRecord
  belongs_to :certificate
  belongs_to :account
  belongs_to :to_organization, class_name: "Organization", foreign_key: "to_organization_id", optional: true

  def split(quantity)
    self.class.create(certificate: certificate, account: account, quantity: self.quantity - quantity, status: "active")
    update(quantity: quantity)
  end

  def retire
    update(status: "retired")
  end

  def cancel_transfer!
    log_transfer_cancellation
    update!(status: "active", to_organization: nil, transfer_initiated_at: nil)
  end

  private

  def log_transfer_cancellation
    Rails.logger.info { {
      msg: "Transfer timeout, cancelling transfer for certificate quantity ID: #{id}.",
      id: id,
      to_organization: to_organization
    } }

    # Not implemented, log to Transactions table.
    # The above log might be in a service object that both logs and creates the Transaction object
    # so it's not this model's responsibility to know how to do this.
    #
    # Transaction.create!(
    #   :auto_cancel_stale_transfer,
    #   certificate_quantity: certificate_quantity.id,
    #   from_status: "intransit",
    #   to_status: "active",
    #   to_organization: certificate_quantity.to_organization
    # )
  end
end
