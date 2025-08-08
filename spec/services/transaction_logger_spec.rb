require 'rails_helper'

RSpec.describe TransactionLogger do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:generation) { create(:generation, generator: generator) }
  let(:certificate) { create(:certificate, generator: generator, generation: generation, quantity: 1000) }
  let(:account) { organization.default_account }
  let(:certificate_quantity) { create(:certificate_quantity, certificate: certificate, account: account, quantity: 1000) }
  
  let(:logger) { described_class.new(user: user, organization: organization) }

  describe '#initialize' do
    it 'sets user and organization' do
      expect(logger.user).to eq(user)
      expect(logger.organization).to eq(organization)
    end

    it 'generates request_id if not provided' do
      expect(logger.request_id).to be_present
    end

    it 'uses provided request_id' do
      custom_logger = described_class.new(user: user, request_id: 'custom-123')
      expect(custom_logger.request_id).to eq('custom-123')
    end

    it 'infers organization from user if not provided' do
      logger_without_org = described_class.new(user: user)
      expect(logger_without_org.organization).to eq(organization)
    end
  end

  describe '#log_certificate_issuance' do
    it 'creates a transaction log for certificate issuance' do
      initial_count = Transaction.count
      
      logger.log_certificate_issuance(certificate, certificate_quantity)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_issued')
      expect(transaction.success).to be true
      expect(transaction.certificate).to eq(certificate)
      expect(transaction.certificate_quantity).to eq(certificate_quantity)
      expect(transaction.generation).to eq(generation)
      expect(transaction.account).to eq(account)
      expect(transaction.quantity_after).to eq(1000)
      expect(transaction.metadata['vintage_date']).to eq(certificate.vintage_date.to_s)
      expect(transaction.metadata['generator_id']).to eq(generator.id)
    end
  end

  describe '#log_certificate_split' do
    let(:new_cq) { create(:certificate_quantity, certificate: certificate, account: account, quantity: 300) }

    before do
      certificate_quantity.update!(quantity: 700)
    end

    it 'creates a transaction log for certificate split' do
      initial_count = Transaction.count
      
      logger.log_certificate_split(certificate_quantity, new_cq, 300)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_split')
      expect(transaction.certificate).to eq(certificate)
      expect(transaction.certificate_quantity).to eq(certificate_quantity)
      expect(transaction.new_certificate_quantity).to eq(new_cq)
      expect(transaction.quantity_before).to eq(1000)
      expect(transaction.quantity_after).to eq(700)
      expect(transaction.quantity_changed).to eq(300)
      expect(transaction.status_before).to eq('active')
      expect(transaction.status_after).to eq('active')
      expect(transaction.metadata['split_quantity']).to eq(300)
    end
  end

  describe '#log_transfer_initiated' do
    let(:target_org) { create(:organization, name: 'Target Org') }

    it 'creates a transaction log for transfer initiation' do
      initial_count = Transaction.count
      
      logger.log_transfer_initiated(certificate_quantity, account, target_org)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_transfer_initiated')
      expect(transaction.certificate_quantity).to eq(certificate_quantity)
      expect(transaction.account).to eq(account)
      expect(transaction.target_organization).to eq(target_org)
      expect(transaction.status_before).to eq('active')
      expect(transaction.status_after).to eq('intransit')
      expect(transaction.metadata['to_organization_id']).to eq(target_org.id)
    end
  end

  describe '#log_transfer_accepted' do
    let(:to_account) { create(:account, organization: organization) }

    it 'creates a transaction log for transfer acceptance' do
      initial_count = Transaction.count
      
      logger.log_transfer_accepted(certificate_quantity, to_account)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_transfer_accepted')
      expect(transaction.certificate_quantity).to eq(certificate_quantity)
      expect(transaction.target_account).to eq(to_account)
      expect(transaction.status_before).to eq('intransit')
      expect(transaction.status_after).to eq('active')
      expect(transaction.metadata['to_account_id']).to eq(to_account.id)
    end
  end

  describe '#log_transfer_cancelled' do
    it 'creates a transaction log for transfer cancellation' do
      initial_count = Transaction.count
      
      logger.log_transfer_cancelled(certificate_quantity)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_transfer_cancelled')
      expect(transaction.certificate_quantity).to eq(certificate_quantity)
      expect(transaction.status_before).to eq('intransit')
      expect(transaction.status_after).to eq('active')
      expect(transaction.metadata['cancelled_by']).to eq(user.id)
    end
  end

  describe '#log_internal_transfer' do
    let(:from_account) { account }
    let(:to_account) { create(:account, organization: organization) }

    it 'creates a transaction log for internal transfer' do
      initial_count = Transaction.count
      
      logger.log_internal_transfer(certificate_quantity, from_account, to_account)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_transfer_initiated')
      expect(transaction.certificate_quantity).to eq(certificate_quantity)
      expect(transaction.account).to eq(from_account)
      expect(transaction.target_account).to eq(to_account)
      expect(transaction.status_before).to eq('active')
      expect(transaction.status_after).to eq('active')
      expect(transaction.metadata['transfer_type']).to eq('internal')
    end
  end

  describe '#log_retirement' do
    it 'creates a transaction log for retirement' do
      initial_count = Transaction.count
      
      logger.log_retirement(certificate_quantity)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_retired')
      expect(transaction.certificate_quantity).to eq(certificate_quantity)
      expect(transaction.status_before).to eq('active')
      expect(transaction.status_after).to eq('retired')
      expect(transaction.metadata['retired_by']).to eq(user.id)
      expect(transaction.metadata['retirement_date']).to be_present
    end
  end

  describe '#log_generation_created' do
    it 'creates a transaction log for generation creation' do
      initial_count = Transaction.count
      
      logger.log_generation_created(generation)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('generation_created')
      expect(transaction.organization).to eq(organization)
      expect(transaction.quantity_after).to eq(generation.quantity)
      expect(transaction.metadata['generation_id']).to eq(generation.id)
      expect(transaction.metadata['generator_id']).to eq(generator.id)
      expect(transaction.metadata['start_date']).to eq(generation.start_date.to_s)
      expect(transaction.metadata['end_date']).to eq(generation.end_date.to_s)
    end
  end

  describe '#log_error' do
    let(:error) { StandardError.new('Something went wrong') }

    it 'creates a failed transaction log' do
      initial_count = Transaction.count
      
      logger.log_error('certificate_issued', error, certificate: certificate)
      
      expect(Transaction.count).to eq(initial_count + 1)

      transaction = Transaction.last
      expect(transaction.event_type).to eq('certificate_issued')
      expect(transaction.success).to be false
      expect(transaction.error_message).to eq('Something went wrong')
      expect(transaction.certificate).to eq(certificate)
      expect(transaction.metadata['error_class']).to eq('StandardError')
      expect(transaction.metadata['backtrace']).to be_an(Array)
    end

    it 'merges additional metadata' do
      logger.log_error('certificate_issued', error, 
                      certificate: certificate,
                      metadata: { custom_field: 'value' })

      transaction = Transaction.last
      expect(transaction.metadata['custom_field']).to eq('value')
      expect(transaction.metadata['error_class']).to eq('StandardError')
    end
  end

  describe 'request tracking' do
    it 'includes request_id in all logged transactions' do
      custom_logger = described_class.new(user: user, request_id: 'req-123')
      
      custom_logger.log_certificate_issuance(certificate, certificate_quantity)
      
      transaction = Transaction.last
      expect(transaction.request_id).to eq('req-123')
    end

    it 'includes ip_address if provided' do
      custom_logger = described_class.new(user: user, ip_address: '192.168.1.1')
      
      custom_logger.log_certificate_issuance(certificate, certificate_quantity)
      
      transaction = Transaction.last
      expect(transaction.ip_address).to eq('192.168.1.1')
    end
  end
end
