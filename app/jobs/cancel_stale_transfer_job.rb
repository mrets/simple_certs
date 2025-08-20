class CancelStaleTransferJob < ApplicationJob
  queue_as :default

  def perform(certificate_quantity_id)
    CertificateQuantity.transaction do
      certificate_quantity = CertificateQuantity.find(certificate_quantity_id)
      certificate_quantity.update(status: 'active', to_organization: nil)
      # log_cancellation(certificate_quantity)
    end
  end

  private

  def log_cancellation(event_data = nil)
    # LoggingService.call(event_data) if event_data
  end
end
