require 'rails_helper'

describe Certificate do
  let(:generator) { create(:generator) }
  let(:generation) { create(:generation, quantity: 5, generator: generator) }
  subject { generation.certificate }

  it 'sets the serial number base correctly' do
    expect(subject.sn_base).to match(/^#{subject.vintage_date.strftime('%Y-%m')}/)
  end

  it 'creates a certificate quantity with the same quantity' do
    expect(subject.certificate_quantities.map(&:quantity)).to eq([ 5 ])
  end

  it 'puts the certificate in the organizations default account' do
    expect(subject.certificate_quantities.map(&:account_id)).to eq([ generator.organization.default_account_id ])
  end

  describe 'transaction logging' do
    let(:organization) { create(:organization) }
    let(:generator) { create(:generator, organization: organization) }
    let(:generation) { create(:generation, generator: generator) }
    let(:certificate) { build(:certificate, generator: generator, generation: generation, quantity: 500, certificate_quantities: []) }

    describe 'on creation' do
      it 'logs certificate issuance when certificate quantity is created' do
        # Clear any existing transactions
        Transaction.destroy_all
        
        certificate.save!
        
        issuance_logs = Transaction.where(event_type: 'certificate_issued')
        expect(issuance_logs.count).to eq(1)

        issuance_log = Transaction.find_by(
          event_type: 'certificate_issued',
          certificate_id: certificate.id
        )
        expect(issuance_log).to be_present
        expect(issuance_log.success).to be true
        expect(issuance_log.certificate).to eq(certificate)
        expect(issuance_log.certificate_quantity).to eq(certificate.certificate_quantities.first)
        expect(issuance_log.quantity_after).to eq(500)
        expect(issuance_log.metadata['vintage_date']).to eq(certificate.vintage_date.to_s)
        expect(issuance_log.metadata['serial_number']).to eq(certificate.sn_base)
        expect(issuance_log.metadata['generator_id']).to eq(generator.id)
      end

      it 'creates certificate quantity with correct attributes' do
        certificate.save!
        
        certificate_quantity = certificate.certificate_quantities.first
        expect(certificate_quantity).to be_present
        expect(certificate_quantity.quantity).to eq(500)
        expect(certificate_quantity.account).to eq(organization.default_account)
        expect(certificate_quantity.status).to eq('active')
      end

      it 'assigns vintage date based on generation end date' do
        certificate.save!
        
        expect(certificate.vintage_date).to eq(generation.end_date.beginning_of_month)
      end

      it 'generates serial number with correct format' do
        certificate.save!
        
        expect(certificate.sn_base).to match(/^\d{4}-\d{2}-[a-f0-9]{8}$/)
        expect(certificate.sn_base).to start_with(certificate.vintage_date.strftime('%Y-%m'))
      end
    end

    describe 'error handling' do
      before do
        # Force an error during certificate quantity creation
        allow_any_instance_of(CertificateQuantity).to receive(:save!).and_raise(StandardError.new("CQ creation failed"))
      end

      it 'logs error when certificate quantity creation fails' do
        initial_count = Transaction.where(success: false).count
        
        begin
          certificate.save!
        rescue StandardError => e
          # Expected to raise
          expect(e.message).to eq('CQ creation failed')
        end
        
        error_logs = Transaction.where(success: false)
        expect(error_logs.count).to eq(initial_count + 1)
        
        error_log = error_logs.last
        expect(error_log.event_type).to eq('certificate_issued')
        expect(error_log.error_message).to eq('CQ creation failed')
        expect(error_log.certificate).to eq(certificate)
        expect(error_log.metadata['error_class']).to eq('StandardError')
        expect(error_log.metadata['generator_id']).to eq(generator.id)
        expect(error_log.metadata['generation_id']).to eq(generation.id)
      end

      it 'rolls back certificate creation when certificate quantity creation fails' do
        expect {
          begin
            certificate.save!
          rescue StandardError
            # Expected to raise
          end
        }.not_to change(Certificate, :count)
      end
    end

    describe 'atomicity' do
      it 'creates certificate and certificate quantity in single transaction' do
        initial_cert_count = Certificate.count
        initial_cq_count = CertificateQuantity.count
        initial_trans_count = Transaction.count
        
        certificate.save!
        
        expect(Certificate.count).to eq(initial_cert_count + 1)
        expect(CertificateQuantity.count).to eq(initial_cq_count + 1)
        expect(Transaction.count).to be >= initial_trans_count + 1
      end
    end
  end
end
