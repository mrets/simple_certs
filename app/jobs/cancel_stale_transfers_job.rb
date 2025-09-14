class CancelStaleTransfersJob < ApplicationJob
  queue_as :default

  # Prevents multiple instances from running simultaneously, allow if a job is still running after 60 minutes
  limits_concurrency to: 1, key: -> { "cancel_stale_transfers" }, duration: 60.minutes

  def perform
    stale_certificate_quantities.find_each do |certificate_quantity|
      certificate_quantity.cancel_transfer!
    end
  end

  private

  def stale_certificate_quantities
    CertificateQuantity.where(status: "intransit").where("transfer_initiated_at < ?", stale_cutoff)
  end

  def stale_cutoff
    24.hours.ago
  end
end
