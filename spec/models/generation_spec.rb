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

  describe 'transaction logging' do
    let(:organization) { create(:organization) }
    let(:generator) { create(:generator, organization: organization) }
    let(:generation) { build(:generation, generator: generator, quantity: 100) }

    describe 'on creation' do
      it 'logs generation creation' do
        expect {
          generation.save!
        }.to change(Transaction, :count).by_at_least(1)

        generation_log = Transaction.find_by(event_type: 'generation_created')
        expect(generation_log).to be_present
        expect(generation_log.success).to be true
        expect(generation_log.organization).to eq(organization)
        expect(generation_log.quantity_after).to eq(100)
        expect(generation_log.metadata['generation_id']).to eq(generation.id)
        expect(generation_log.metadata['generator_id']).to eq(generator.id)
      end

      it 'logs certificate issuance' do
        expect {
          generation.save!
        }.to change(Transaction.where(event_type: 'certificate_issued'), :count).by(1)

        issuance_log = Transaction.find_by(event_type: 'certificate_issued')
        expect(issuance_log).to be_present
        expect(issuance_log.success).to be true
        expect(issuance_log.certificate).to eq(generation.certificate)
        expect(issuance_log.quantity_after).to eq(100)
      end

      it 'creates all records atomically' do
        generation.save!
        
        expect(generation.certificate).to be_present
        expect(generation.certificate.certificate_quantities.count).to eq(1)
        expect(Transaction.where(event_type: ['generation_created', 'certificate_issued']).count).to eq(2)
      end
    end

    describe 'error handling' do
      before do
        # Force an error during certificate creation
        allow_any_instance_of(Certificate).to receive(:save!).and_raise(StandardError.new("Test error"))
      end

      it 'logs error when certificate creation fails' do
        expect {
          begin
            generation.save!
          rescue StandardError
            # Expected to raise
          end
        }.to change(Transaction.where(success: false), :count).by(1)

        error_log = Transaction.find_by(success: false)
        expect(error_log.event_type).to eq('certificate_issued')
        expect(error_log.error_message).to eq('Test error')
        expect(error_log.metadata['error_class']).to eq('StandardError')
      end

      it 'does not rollback generation when certificate creation fails in after_commit' do
        # The generation is created and committed, then after_commit runs
        # If certificate creation fails in after_commit, generation stays
        expect {
          begin
            generation.save!
          rescue StandardError
            # Expected to raise  
          end
        }.to change(Generation, :count).by(1)
      end
    end
  end
end
