class CancelStaleTransfersJob < ApplicationJob
  queue_as :default

  def perform
    stale_certificate_quantities.find_each do |certificate_quantity|
      log_certificate_quantity_transfer_cancellation(certificate_quantity)
      certificate_quantity.status = "active"
      certificate_quantity.to_organization = nil
      certificate_quantity.transfer_initiated_at = nil
      certificate_quantity.save!
    end
  end

  private

  def stale_certificate_quantities
    CertificateQuantity.where(status: "intransit").where("transfer_initiated_at < ?", stale_cutoff)
  end

  def stale_cutoff
    24.hours.ago
  end

  def log_certificate_quantity_transfer_cancellation(certificate_quantity)
    Rails.logger.info { {
      msg: "Transfer timeout, cancelling transfer for certificate quantity ID: #{certificate_quantity.id}.",
      id: certificate_quantity.id,
      to_organization: certificate_quantity.to_organization
    } }

    # Not implemented, log to Transactions table.
    # The above log might be in a service object that both logs and creates the Transaction object
    # so it's not this job's responsibility to know how to do this.
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
