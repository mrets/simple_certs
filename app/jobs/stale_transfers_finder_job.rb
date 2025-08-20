class StaleTransfersFinderJob < ApplicationJob
  queue_as :default

  def perform
    CertificateQuantity.intransit.where(status_changed_at: ..24.hours.ago).find_each do |cq|
      CancelStaleTransferJob.perform_later(cq.id)
    end
  end
end
