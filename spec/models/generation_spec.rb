require 'rails_helper'

describe Generation do
  subject { create(:generation, quantity: 5, certificate: nil) }
  describe '#issue_certificate' do
    before do
      subject.issue_certificate
    end

    let(:certificate) { subject.certificate }

    it 'creates a certificate with the same quantity as the generation' do
      expect(certificate.quantity).to eq(subject.quantity)
    end

    it 'creates a certificate with the same generator as the generation' do
      expect(certificate.generator).to eq(subject.generator)
    end

    it 'creates a certificate with the vintage as the same month as the end date' do
      expect(certificate.vintage_date).to eq(subject.end_date.beginning_of_month)
    end

    it 'creates a one certificate quantity associated with the created certificate' do
      expect(certificate.certificate_quantities.count).to eq(1)
    end
  end
end