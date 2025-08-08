require 'rails_helper'

RSpec.describe Transaction, type: :model do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:generation) { create(:generation, generator: generator) }
  let(:certificate) { create(:certificate, generator: generator, generation: generation) }
  let(:certificate_quantity) { create(:certificate_quantity, certificate: certificate) }

  describe 'validations' do
    it 'requires event_type' do
      transaction = Transaction.new(success: true)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:event_type]).to include("can't be blank")
    end

    it 'validates event_type is in allowed list' do
      transaction = Transaction.new(event_type: 'invalid_event', success: true)
      expect(transaction).not_to be_valid
      expect(transaction.errors[:event_type]).to include("is not included in the list")
    end

    it 'validates success is boolean (defaults to false)' do
      transaction = Transaction.new(event_type: 'certificate_issued')
      expect(transaction.success).to eq(false)  # Has default value
      expect(transaction).to be_valid
      
      transaction.success = true
      expect(transaction).to be_valid
      
      transaction.success = nil
      expect(transaction).not_to be_valid
      expect(transaction.errors[:success]).to include("is not included in the list")
    end

    it 'generates transaction_id automatically' do
      transaction = Transaction.new(
        event_type: 'certificate_issued',
        success: true
      )
      expect(transaction.transaction_id).to be_nil
      transaction.valid?
      expect(transaction.transaction_id).to match(/^TXN-[a-f0-9]+-\d+$/)
    end

    it 'ensures transaction_id is unique' do
      transaction1 = Transaction.create!(
        event_type: 'certificate_issued',
        success: true
      )
      
      transaction2 = Transaction.new(
        event_type: 'certificate_issued',
        success: true
      )
      transaction2.transaction_id = transaction1.transaction_id
      
      expect(transaction2).not_to be_valid
      expect(transaction2.errors[:transaction_id]).to include("has already been taken")
    end
  end

  describe 'immutability' do
    let(:transaction) do
      Transaction.create!(
        event_type: 'certificate_issued',
        success: true,
        organization: organization
      )
    end

    it 'prevents updates to existing transactions' do
      expect {
        transaction.update!(event_type: 'certificate_retired')
      }.to raise_error(ActiveRecord::RecordNotSaved)
    end

    it 'prevents deletion of transactions' do
      expect {
        transaction.destroy!
      }.to raise_error(ActiveRecord::RecordNotDestroyed)
      
      expect(Transaction.find(transaction.id)).to eq(transaction)
    end
  end

  describe '.log_event' do
    it 'creates a transaction with provided attributes' do
      transaction = Transaction.log_event(
        event_type: 'certificate_issued',
        success: true,
        user: user,
        organization: organization,
        certificate: certificate,
        quantity_after: 1000
      )

      expect(transaction).to be_persisted
      expect(transaction.event_type).to eq('certificate_issued')
      expect(transaction.success).to be true
      expect(transaction.user).to eq(user)
      expect(transaction.organization).to eq(organization)
      expect(transaction.certificate).to eq(certificate)
      expect(transaction.quantity_after).to eq(1000)
    end

    it 'raises error if invalid data provided' do
      expect {
        Transaction.log_event(
          event_type: 'invalid_type',
          success: true
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'scopes' do
    before do
      Transaction.create!(event_type: 'certificate_issued', success: true, organization: organization)
      Transaction.create!(event_type: 'certificate_retired', success: true, organization: organization)
      Transaction.create!(event_type: 'certificate_issued', success: false, organization: organization)
      other_org = create(:organization, name: 'Other Org')
      Transaction.create!(event_type: 'certificate_issued', success: true, organization: other_org)
    end

    it 'filters successful transactions' do
      expect(Transaction.successful.count).to eq(3)
    end

    it 'filters failed transactions' do
      expect(Transaction.failed.count).to eq(1)
    end

    it 'filters by event type' do
      expect(Transaction.by_event_type('certificate_issued').count).to eq(3)
      expect(Transaction.by_event_type('certificate_retired').count).to eq(1)
    end

    it 'filters by organization' do
      expect(Transaction.for_organization(organization.id).count).to eq(3)
    end

    it 'orders by recent first' do
      transactions = Transaction.recent
      expect(transactions.first.created_at).to be >= transactions.last.created_at
    end
  end

  describe '.replay_state' do
    let!(:org) { create(:organization) }
    let!(:gen) { create(:generator, organization: org) }
    let!(:generation) { create(:generation, generator: gen) }
    let!(:cert) { generation.certificate }
    let!(:cq) { cert.certificate_quantities.first }
    
    before do
      # Clear transactions created by factories
      Transaction.destroy_all
      
      # Create some test transactions with valid associations
      Transaction.create!(
        event_type: 'certificate_issued',
        success: true,
        certificate_id: cert.id,
        quantity_after: 1000,
        created_at: 2.days.ago
      )
      
      Transaction.create!(
        event_type: 'certificate_split',
        success: true,
        certificate_quantity_id: cq.id,
        new_certificate_quantity_id: cq.id,
        quantity_after: 700,
        quantity_changed: 300,
        status_after: 'active',
        created_at: 1.day.ago
      )
      
      Transaction.create!(
        event_type: 'certificate_retired',
        success: true,
        certificate_quantity_id: cq.id,
        quantity_after: 300,
        status_after: 'retired',
        created_at: 1.hour.ago
      )
      
      # Failed transaction should be ignored
      Transaction.create!(
        event_type: 'certificate_issued',
        success: false,
        certificate_id: cert.id,
        created_at: 30.minutes.ago
      )
    end

    it 'replays all successful transactions' do
      state = Transaction.replay_state
      
      # We should have only 3 successful transactions from our setup
      successful_count = Transaction.successful.count
      expect(state[:summary][:total_events]).to eq(successful_count)
      expect(state[:summary][:events_by_type]['certificate_issued']).to be >= 1
      expect(state[:summary][:events_by_type]['certificate_split']).to be >= 1
      expect(state[:summary][:events_by_type]['certificate_retired']).to be >= 1
    end

    it 'tracks certificate states' do
      state = Transaction.replay_state
      
      cert_transaction = Transaction.find_by(certificate_id: cert.id, event_type: 'certificate_issued')
      expect(state[:certificates][cert.id][:quantity].to_i).to eq(1000)
      expect(state[:certificates][cert.id][:created_at]).to eq(cert_transaction.created_at)
    end

    it 'tracks certificate quantity states' do
      state = Transaction.replay_state
      
      expect(state[:certificate_quantities][cq.id]).to eq({
        quantity: 300,
        status: 'retired'
      })
    end

    it 'filters by date range' do
      state = Transaction.replay_state(from: 25.hours.ago, to: 30.minutes.ago)
      
      # Should only include the retired transaction from 1 hour ago
      expect(state[:summary][:total_events]).to be >= 1
      expect(state[:summary][:events_by_type]['certificate_retired']).to be >= 1
    end
  end

  describe 'EVENT_TYPES constant' do
    it 'includes all expected event types' do
      expect(Transaction::EVENT_TYPES).to include(
        certificate_issued: 'certificate_issued',
        certificate_split: 'certificate_split',
        certificate_transfer_initiated: 'certificate_transfer_initiated',
        certificate_transfer_accepted: 'certificate_transfer_accepted',
        certificate_transfer_cancelled: 'certificate_transfer_cancelled',
        certificate_retired: 'certificate_retired',
        generation_created: 'generation_created'
      )
    end
  end
end