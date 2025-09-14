require 'rails_helper'

describe "CertificateQuantity" do
  describe "#cancel_transfer!" do
    let(:other_organization) { create(:organization) }
    let(:generation) { create(:generation, quantity: 5, generator: create(:generator)) }
    let(:certificate_quantity) { generation.certificate.certificate_quantities.first }

    before do
      certificate_quantity.update!(
        status: "intransit",
        to_organization: other_organization,
        transfer_initiated_at: 1.hour.ago
      )
      certificate_quantity.cancel_transfer!
    end

    it "resets the status to active" do
      expect(certificate_quantity.reload.status).to eq("active")
    end

    it "clears the to_organization" do
      expect(certificate_quantity.reload.to_organization).to be_nil
    end

    it "clears the transfer_initiated_at timestamp" do
      expect(certificate_quantity.reload.transfer_initiated_at).to be_nil
    end

    it "logs the transfer cancellation" do
      expect(Rails.logger).to receive(:info)

      certificate_quantity.cancel_transfer!
    end
  end
end
