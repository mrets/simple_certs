require 'rails_helper'

describe Generation do

  context 'when testing start and end dates' do
    subject { build(:generation, start_date: start_date, end_date: end_date) }

    context 'when start date is before the end date' do
      let(:start_date) { 2.days.ago }
      let(:end_date) { 1.day.ago }

      it 'be valid' do
        expect(subject).to be_valid
      end
    end

    context 'when start date is equal to the end date' do
      let(:start_date) { 1.days.ago }
      let(:end_date) { 1.day.ago }

      it 'be valid' do
        expect(subject).to be_valid
      end
    end

    context 'when start date is after the end date' do
      let(:start_date) { 1.days.ago }
      let(:end_date) { 2.day.ago }

      it 'not be valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'when the end date is in the future' do
      let(:start_date) { 1.days.ago }
      let(:end_date) { 1.day.from_now }

      it 'not be valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'when the start date is in the future' do
      let(:start_date) { 1.days.from_now }
      let(:end_date) { 2.days.from_now }

      it 'not be valid' do
        expect(subject).not_to be_valid
      end
    end
  end

  # issue_certificate is called after_create
  describe '#issue_certificate' do
    subject { create(:generation, quantity: 5, certificate: nil) }
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