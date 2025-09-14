require "rails_helper"

RSpec.describe "CancelStaleTransfersJob", type: :job do
  def create_certificate_quantity
    generation = create(:generation)
    certificate = generation.certificate
    certificate_quantity = certificate.certificate_quantities.first
    certificate_quantity.update!(
      status: "intransit",
      to_organization: create(:organization),
      transfer_initiated_at: 25.hours.ago
    )
    certificate_quantity
  end

  it "resets intransit certificate quantities in transit for over 24 hours" do
    certificate_quantity = create_certificate_quantity

    CancelStaleTransfersJob.perform_now

    certificate_quantity.reload
    expect(certificate_quantity.status).to eq("active")
    expect(certificate_quantity.transfer_initiated_at).to be_nil
    expect(certificate_quantity.to_organization).to be_nil
  end

  it "does not reset intransit certificate quantities in transit for under 24 hours" do
    certificate_quantity = create_certificate_quantity
    certificate_quantity.update!(transfer_initiated_at: 23.hours.ago)

    CancelStaleTransfersJob.perform_now

    certificate_quantity.reload
    expect(certificate_quantity.status).to eq("intransit")
    expect(certificate_quantity.transfer_initiated_at).to be_present
    expect(certificate_quantity.to_organization).to be_present
  end

  it "does not reset active certificate quantities" do
    certificate_quantity = create_certificate_quantity
    certificate_quantity.update!(transfer_initiated_at: nil, status: "active", to_organization: nil)

    CancelStaleTransfersJob.perform_now

    certificate_quantity.reload
    expect(certificate_quantity.status).to eq("active")
    expect(certificate_quantity.transfer_initiated_at).to be_nil
    expect(certificate_quantity.to_organization).to be_nil
  end
end
