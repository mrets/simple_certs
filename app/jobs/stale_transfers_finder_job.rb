class StaleTransfersFinderJob < ApplicationJob
  queue_as :default

  def perform
    CertificateQuantity.stale_transfers.find_each do |cq|
      CancelStaleTransferJob.perform_later(cq.id)
    end
  end
end
