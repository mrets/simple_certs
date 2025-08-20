require 'rails_helper'

describe CancelStaleTransferJob do
  let(:stale_transfer) { create(:certificate_quantity, :stale) }

  it "updates status_changed_at, status, and to_organization" do
    expect { described_class.perform_now(stale_transfer.id) }
      .to change { stale_transfer.reload.status }.from('intransit').to('active')
      .and change { stale_transfer.reload.to_organization }.to(nil)
  end
end
