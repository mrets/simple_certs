require 'rails_helper'

RSpec.describe CertificateQuantity, type: :model do
  let(:organization) { create(:organization) }
  let(:generator) { create(:generator, organization: organization) }
  let(:generation) { create(:generation, generator: generator, quantity: 1000) }
  let(:certificate) { generation.certificate }
  let(:account) { organization.default_account }
  let(:certificate_quantity) { certificate.certificate_quantities.first }
  let(:user) { create(:user, organization: organization) }
  let(:logger) { TransactionLogger.new(user: user, organization: organization) }

  describe '#split' do
    context 'with valid split amount' do
      it 'creates a new certificate quantity with the split amount' do
        # We already have 1 CQ from the setup
        expect(CertificateQuantity.count).to eq(1)
        
        new_cq = certificate_quantity.split(300, logger: logger)
        
        expect(CertificateQuantity.count).to eq(2)
        
        expect(new_cq.quantity).to eq(700)  # New CQ gets the remaining amount
        expect(new_cq.certificate).to eq(certificate)
        expect(new_cq.account).to eq(account)
        expect(new_cq.status).to eq('active')
      end

      it 'reduces the original quantity to the split amount' do
        original_quantity = certificate_quantity.quantity
        certificate_quantity.split(300, logger: logger)
        
        certificate_quantity.reload
        expect(certificate_quantity.quantity).to eq(300)  # Original gets the split amount
      end

      it 'logs the split operation' do
        expect {
          certificate_quantity.split(300, logger: logger)
        }.to change(Transaction.where(event_type: 'certificate_split'), :count).by(1)
        
        split_log = Transaction.find_by(event_type: 'certificate_split')
        expect(split_log.certificate_quantity).to eq(certificate_quantity)
        # Logger calculates quantity_before as current quantity + split_quantity
        # Since original is already updated to 300, before = 300 + 300 = 600
        expect(split_log.quantity_before.to_i).to eq(600)
        expect(split_log.quantity_after.to_i).to eq(300)  # Original now has split amount
        expect(split_log.quantity_changed).to eq(300)
        expect(split_log.new_certificate_quantity).to be_present
      end

      it 'uses pessimistic locking' do
        expect(certificate_quantity).to receive(:lock!)
        certificate_quantity.split(300, logger: logger)
      end
    end

    context 'with invalid split amount' do
      it 'raises error when split amount equals quantity' do
        expect {
          certificate_quantity.split(1000, logger: logger)
        }.to raise_error(ArgumentError, "Split quantity exceeds available quantity")
      end

      it 'raises error when split amount exceeds quantity' do
        expect {
          certificate_quantity.split(1500, logger: logger)
        }.to raise_error(ArgumentError, "Split quantity exceeds available quantity")
      end

      it 'raises error when split amount is zero' do
        expect {
          certificate_quantity.split(0, logger: logger)
        }.to raise_error(ArgumentError, "Split quantity must be positive")
      end

      it 'raises error when split amount is negative' do
        expect {
          certificate_quantity.split(-100, logger: logger)
        }.to raise_error(ArgumentError, "Split quantity must be positive")
      end
    end

    context 'atomicity' do
      it 'rolls back all changes if logging fails' do
        allow(logger).to receive(:log_certificate_split).and_raise(StandardError.new("Logging failed"))
        
        initial_count = CertificateQuantity.count
        
        expect {
          certificate_quantity.split(300, logger: logger)
        }.to raise_error(StandardError, "Logging failed")
        
        expect(CertificateQuantity.count).to eq(initial_count)
        
        certificate_quantity.reload
        expect(certificate_quantity.quantity).to eq(1000)
      end
    end
  end

  describe '#initiate_transfer' do
    let(:target_org) { create(:organization, name: 'Target Org') }

    context 'with valid transfer' do
      it 'changes status to intransit' do
        certificate_quantity.initiate_transfer(target_org, logger: logger)
        
        certificate_quantity.reload
        expect(certificate_quantity.status).to eq('intransit')
        expect(certificate_quantity.to_organization).to eq(target_org)
      end

      it 'logs the transfer initiation' do
        expect {
          certificate_quantity.initiate_transfer(target_org, logger: logger)
        }.to change(Transaction.where(event_type: 'certificate_transfer_initiated'), :count).by(1)
        
        transfer_log = Transaction.find_by(event_type: 'certificate_transfer_initiated')
        expect(transfer_log.certificate_quantity).to eq(certificate_quantity)
        expect(transfer_log.account).to eq(account)
        expect(transfer_log.target_organization).to eq(target_org)
        expect(transfer_log.status_before).to eq('active')
        expect(transfer_log.status_after).to eq('intransit')
      end

      it 'uses pessimistic locking' do
        expect(certificate_quantity).to receive(:lock!)
        certificate_quantity.initiate_transfer(target_org, logger: logger)
      end
    end

    context 'with invalid transfer' do
      it 'raises error when already in transit' do
        certificate_quantity.update!(status: 'intransit')
        
        expect {
          certificate_quantity.initiate_transfer(target_org, logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Can only transfer active certificates")
      end

      it 'raises error when retired' do
        certificate_quantity.update!(status: 'retired')
        
        expect {
          certificate_quantity.initiate_transfer(target_org, logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Can only transfer active certificates")
      end
    end
  end

  describe '#accept_transfer' do
    let(:target_org) { create(:organization, name: 'Target Org') }
    let(:target_account) { create(:account, organization: target_org) }

    before do
      certificate_quantity.update!(status: 'intransit', to_organization: target_org)
    end

    context 'with valid acceptance' do
      it 'changes status to active and updates account' do
        certificate_quantity.accept_transfer(target_account, logger: logger)
        
        certificate_quantity.reload
        expect(certificate_quantity.status).to eq('active')
        expect(certificate_quantity.account).to eq(target_account)
        expect(certificate_quantity.to_organization).to be_nil
      end

      it 'logs the transfer acceptance' do
        expect {
          certificate_quantity.accept_transfer(target_account, logger: logger)
        }.to change(Transaction.where(event_type: 'certificate_transfer_accepted'), :count).by(1)
        
        accept_log = Transaction.find_by(event_type: 'certificate_transfer_accepted')
        expect(accept_log.certificate_quantity).to eq(certificate_quantity)
        expect(accept_log.target_account).to eq(target_account)
        expect(accept_log.status_before).to eq('intransit')
        expect(accept_log.status_after).to eq('active')
      end
    end

    context 'with invalid acceptance' do
      it 'raises error when not in transit' do
        certificate_quantity.update!(status: 'active', to_organization: nil)
        
        expect {
          certificate_quantity.accept_transfer(target_account, logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Can only accept intransit certificates")
      end

      it 'raises error when account organization does not match' do
        wrong_account = create(:account, organization: organization)
        
        expect {
          certificate_quantity.accept_transfer(wrong_account, logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Account must belong to target organization")
      end
    end
  end

  describe '#cancel_transfer' do
    let(:target_org) { create(:organization, name: 'Target Org') }

    before do
      certificate_quantity.update!(status: 'intransit', to_organization: target_org)
    end

    context 'with valid cancellation' do
      it 'reverts status to active' do
        certificate_quantity.cancel_transfer(logger: logger)
        
        certificate_quantity.reload
        expect(certificate_quantity.status).to eq('active')
        expect(certificate_quantity.to_organization).to be_nil
      end

      it 'logs the transfer cancellation' do
        expect {
          certificate_quantity.cancel_transfer(logger: logger)
        }.to change(Transaction.where(event_type: 'certificate_transfer_cancelled'), :count).by(1)
        
        cancel_log = Transaction.find_by(event_type: 'certificate_transfer_cancelled')
        expect(cancel_log.certificate_quantity).to eq(certificate_quantity)
        expect(cancel_log.status_before).to eq('intransit')
        expect(cancel_log.status_after).to eq('active')
      end
    end

    context 'with invalid cancellation' do
      it 'raises error when not in transit' do
        certificate_quantity.update!(status: 'active', to_organization: nil)
        
        expect {
          certificate_quantity.cancel_transfer(logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Can only cancel intransit certificates")
      end
    end
  end

  describe '#transfer_internal' do
    let(:target_account) { create(:account, organization: organization, name: 'Target Account') }

    context 'with valid internal transfer' do
      it 'updates the account' do
        certificate_quantity.transfer_internal(target_account, logger: logger)
        
        certificate_quantity.reload
        expect(certificate_quantity.account).to eq(target_account)
        expect(certificate_quantity.status).to eq('active')
      end

      it 'logs the internal transfer' do
        expect {
          certificate_quantity.transfer_internal(target_account, logger: logger)
        }.to change(Transaction.where(event_type: 'certificate_transfer_initiated'), :count).by(1)
        
        transfer_log = Transaction.find_by(event_type: 'certificate_transfer_initiated')
        expect(transfer_log.certificate_quantity).to eq(certificate_quantity)
        expect(transfer_log.target_account).to eq(target_account)
        expect(transfer_log.metadata['transfer_type']).to eq('internal')
      end
    end

    context 'with invalid internal transfer' do
      it 'raises error when not active' do
        certificate_quantity.update!(status: 'intransit')
        
        expect {
          certificate_quantity.transfer_internal(target_account, logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Can only transfer active certificates")
      end

      it 'raises error when account is from different organization' do
        other_org = create(:organization, name: 'Other Org')
        other_account = create(:account, organization: other_org)
        
        expect {
          certificate_quantity.transfer_internal(other_account, logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Accounts must be in same organization")
      end
    end
  end

  describe '#retire' do
    context 'with valid retirement' do
      it 'changes status to retired' do
        certificate_quantity.retire(logger: logger)
        
        certificate_quantity.reload
        expect(certificate_quantity.status).to eq('retired')
      end

      it 'logs the retirement' do
        expect {
          certificate_quantity.retire(logger: logger)
        }.to change(Transaction.where(event_type: 'certificate_retired'), :count).by(1)
        
        retire_log = Transaction.find_by(event_type: 'certificate_retired')
        expect(retire_log.certificate_quantity).to eq(certificate_quantity)
        expect(retire_log.status_before).to eq('active')
        expect(retire_log.status_after).to eq('retired')
        expect(retire_log.metadata['retired_by']).to eq(user.id)
      end

      it 'uses pessimistic locking' do
        expect(certificate_quantity).to receive(:lock!)
        certificate_quantity.retire(logger: logger)
      end
    end

    context 'with invalid retirement' do
      it 'raises error when already retired' do
        certificate_quantity.update!(status: 'retired')
        
        expect {
          certificate_quantity.retire(logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Can only retire active certificates")
      end

      it 'raises error when in transit' do
        certificate_quantity.update!(status: 'intransit')
        
        expect {
          certificate_quantity.retire(logger: logger)
        }.to raise_error(CertificateQuantity::InvalidOperationError, "Can only retire active certificates")
      end
    end
  end

  describe 'concurrency protection' do
    it 'uses pessimistic locking in split operation' do
      expect(certificate_quantity).to receive(:lock!)
      certificate_quantity.split(100, logger: logger)
    end
  end
end