require 'rails_helper'

RSpec.describe StaleTransfersFinderJob, type: :job do
  let!(:stale_transfer) { create(:certificate_quantity, :stale) }
  let!(:active_transfer) { create(:certificate_quantity) }

  describe "#perform_later" do
    it "queues job" do
      expect {
        described_class.perform_later
      }.to have_enqueued_job
    end

    it "queues a CancelStaleTranferJob for each record found" do
      expect(CancelStaleTransferJob).to receive(:perform_later).with(stale_transfer.id)
      expect(CancelStaleTransferJob).not_to receive(:perform_later).with(active_transfer.id)

      described_class.perform_now
    end
  end
end
