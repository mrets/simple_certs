require 'rails_helper'

describe Certificate do
  let(:generator) { create(:generator) }
  let(:generation) { create(:generation, quantity: 5, generator: generator) }
  subject { generation.certificate }

  it 'sets the serial number base correctly' do
    expect(subject.sn_base).to match(/^#{subject.vintage_date.strftime('%Y-%m')}/)
  end

  it 'creates a certificate quantity with the same quantity' do
    expect(subject.certificate_quantities.map(&:quantity)).to eq([5])
  end

  it 'puts the certificate in the organizations default account' do
    expect(subject.certificate_quantities.map(&:account_id)).to eq([generator.organization.default_account_id])
  end
end

