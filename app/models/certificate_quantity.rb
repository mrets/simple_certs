class CertificateQuantity < ApplicationRecord
  belongs_to :certificate
  belongs_to :account
  belongs_to :to_organization, class_name: "Organization", foreign_key: "to_organization_id", optional: true
  
  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active retired intransit] }
  
  # Scopes for querying
  scope :active, -> { where(status: 'active') }
  scope :retired, -> { where(status: 'retired') }
  scope :intransit, -> { where(status: 'intransit') }
  
  def split(split_quantity, logger: nil)
    raise ArgumentError, "Split quantity must be positive" if split_quantity <= 0
    raise ArgumentError, "Split quantity exceeds available quantity" if split_quantity >= quantity
    raise InvalidOperationError, "Can only split active certificates" unless status == 'active'
    
    # Use pessimistic locking to prevent concurrent splits
    ActiveRecord::Base.transaction do
      # Lock this record for update
      self.lock!
      
      # Re-check conditions after acquiring lock
      raise ArgumentError, "Split quantity exceeds available quantity" if split_quantity >= quantity
      raise InvalidOperationError, "Can only split active certificates" unless status == 'active'
      
      # Create new certificate quantity with the remaining amount
      new_cq = self.class.create!(
        certificate: certificate,
        account: account,
        quantity: quantity - split_quantity,
        status: 'active'
      )
      
      # Update original with split amount
      update!(quantity: split_quantity)
      
      # Log the transaction
      logger&.log_certificate_split(self, new_cq, split_quantity)
      
      new_cq
    end
  rescue => e
    logger&.log_error(Transaction::EVENT_TYPES[:certificate_split], e, 
                     certificate_quantity: self,
                     metadata: { split_quantity: split_quantity })
    raise
  end
  
  def retire(logger: nil)
    raise InvalidOperationError, "Can only retire active certificates" unless status == 'active'
    
    ActiveRecord::Base.transaction do
      # Lock this record for update
      self.lock!
      
      # Re-check status after acquiring lock
      raise InvalidOperationError, "Can only retire active certificates" unless status == 'active'
      
      # Update status to retired
      update!(status: 'retired')
      
      # Log the transaction
      logger&.log_retirement(self)
    end
  rescue => e
    logger&.log_error(Transaction::EVENT_TYPES[:certificate_retired], e,
                     certificate_quantity: self)
    raise
  end
  
  def initiate_transfer(to_organization, logger: nil)
    raise InvalidOperationError, "Can only transfer active certificates" unless status == 'active'
    raise ArgumentError, "Target organization required" unless to_organization
    
    ActiveRecord::Base.transaction do
      # Lock this record for update
      self.lock!
      
      # Re-check status after acquiring lock
      raise InvalidOperationError, "Can only transfer active certificates" unless status == 'active'
      
      # Update status and set target organization
      update!(
        status: 'intransit',
        to_organization_id: to_organization.id
      )
      
      # Log the transaction
      logger&.log_transfer_initiated(self, account, to_organization)
    end
  rescue => e
    logger&.log_error(Transaction::EVENT_TYPES[:certificate_transfer_initiated], e,
                     certificate_quantity: self,
                     metadata: { to_organization_id: to_organization&.id })
    raise
  end
  
  def accept_transfer(to_account, logger: nil)
    raise InvalidOperationError, "Can only accept intransit certificates" unless status == 'intransit'
    raise ArgumentError, "Target account required" unless to_account
    raise InvalidOperationError, "Account must belong to target organization" unless to_account.organization_id == to_organization_id
    
    ActiveRecord::Base.transaction do
      # Lock this record for update
      self.lock!
      
      # Re-check conditions after acquiring lock
      raise InvalidOperationError, "Can only accept intransit certificates" unless status == 'intransit'
      raise InvalidOperationError, "Account must belong to target organization" unless to_account.organization_id == to_organization_id
      
      # Update status and move to new account
      update!(
        status: 'active',
        account_id: to_account.id,
        to_organization_id: nil
      )
      
      # Log the transaction
      logger&.log_transfer_accepted(self, to_account)
    end
  rescue => e
    logger&.log_error(Transaction::EVENT_TYPES[:certificate_transfer_accepted], e,
                     certificate_quantity: self,
                     metadata: { to_account_id: to_account&.id })
    raise
  end
  
  def cancel_transfer(logger: nil)
    raise InvalidOperationError, "Can only cancel intransit certificates" unless status == 'intransit'
    
    ActiveRecord::Base.transaction do
      # Lock this record for update
      self.lock!
      
      # Re-check status after acquiring lock
      raise InvalidOperationError, "Can only cancel intransit certificates" unless status == 'intransit'
      
      # Revert to active status and clear target organization
      update!(
        status: 'active',
        to_organization_id: nil
      )
      
      # Log the transaction
      logger&.log_transfer_cancelled(self)
    end
  rescue => e
    logger&.log_error(Transaction::EVENT_TYPES[:certificate_transfer_cancelled], e,
                     certificate_quantity: self)
    raise
  end
  
  def transfer_internal(to_account, logger: nil)
    raise InvalidOperationError, "Can only transfer active certificates" unless status == 'active'
    raise ArgumentError, "Target account required" unless to_account
    raise InvalidOperationError, "Accounts must be in same organization" unless account.organization_id == to_account.organization_id
    
    ActiveRecord::Base.transaction do
      # Lock this record for update
      self.lock!
      
      # Re-check conditions after acquiring lock
      raise InvalidOperationError, "Can only transfer active certificates" unless status == 'active'
      raise InvalidOperationError, "Accounts must be in same organization" unless account.organization_id == to_account.organization_id
      
      from_account = account
      
      # Move to new account
      update!(account_id: to_account.id)
      
      # Log the transaction
      logger&.log_internal_transfer(self, from_account, to_account)
    end
  rescue => e
    logger&.log_error(Transaction::EVENT_TYPES[:certificate_transfer_initiated], e,
                     certificate_quantity: self,
                     metadata: { to_account_id: to_account&.id, transfer_type: 'internal' })
    raise
  end
  
  class InvalidOperationError < StandardError; end
end