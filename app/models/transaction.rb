class Transaction < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :organization, optional: true
  belongs_to :certificate, optional: true
  belongs_to :certificate_quantity, optional: true
  belongs_to :generation, optional: true
  belongs_to :account, optional: true
  belongs_to :target_account, class_name: 'Account', optional: true
  belongs_to :target_organization, class_name: 'Organization', optional: true
  belongs_to :new_certificate_quantity, class_name: 'CertificateQuantity', optional: true
  
  # Event types
  EVENT_TYPES = {
    certificate_issued: 'certificate_issued',
    certificate_split: 'certificate_split',
    certificate_transfer_initiated: 'certificate_transfer_initiated',
    certificate_transfer_accepted: 'certificate_transfer_accepted',
    certificate_transfer_cancelled: 'certificate_transfer_cancelled',
    certificate_retired: 'certificate_retired',
    generation_created: 'generation_created'
  }.freeze
  
  # Validations
  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES.values }
  validates :transaction_id, uniqueness: true
  validates :success, inclusion: { in: [true, false] }
  
  # Callbacks to ensure append-only behavior
  before_validation :generate_transaction_id, on: :create
  before_update :prevent_update
  before_destroy :prevent_destroy
  
  # Scopes
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_organization, ->(org_id) { where(organization_id: org_id) }
  scope :for_certificate, ->(cert_id) { where(certificate_id: cert_id) }
  scope :for_certificate_quantity, ->(cq_id) { where(certificate_quantity_id: cq_id) }
  
  class << self
    def log_event(event_type:, success:, user: nil, organization: nil, **attributes)
      transaction = new(
        event_type: event_type,
        success: success,
        user: user,
        organization: organization,
        **attributes
      )
      
      transaction.save!
      transaction
    end
    
    # Replay state from transaction log
    def replay_state(from: nil, to: nil)
      scope = successful
      scope = scope.where('created_at >= ?', from) if from
      scope = scope.where('created_at <= ?', to) if to
      
      state = {
        certificates: {},
        certificate_quantities: {},
        accounts: {},
        summary: {
          total_events: 0,
          events_by_type: Hash.new(0)
        }
      }
      
      scope.order(:created_at).find_each do |transaction|
        state[:summary][:total_events] += 1
        state[:summary][:events_by_type][transaction.event_type] += 1
        
        case transaction.event_type
        when EVENT_TYPES[:certificate_issued]
          state[:certificates][transaction.certificate_id] = {
            quantity: transaction.quantity_after,
            created_at: transaction.created_at
          }
        when EVENT_TYPES[:certificate_split]
          state[:certificate_quantities][transaction.certificate_quantity_id] = {
            quantity: transaction.quantity_after,
            status: transaction.status_after
          }
          if transaction.new_certificate_quantity_id
            state[:certificate_quantities][transaction.new_certificate_quantity_id] = {
              quantity: transaction.quantity_changed,
              status: 'active'
            }
          end
        when EVENT_TYPES[:certificate_retired]
          state[:certificate_quantities][transaction.certificate_quantity_id] = {
            quantity: transaction.quantity_after,
            status: 'retired'
          }
        end
      end
      
      state
    end
  end
  
  private
  
  def generate_transaction_id
    self.transaction_id ||= "TXN-#{SecureRandom.hex(16)}-#{Time.current.to_i}"
  end
  
  def prevent_update
    if persisted?
      errors.add(:base, "Transactions are immutable and cannot be updated")
      throw :abort
    end
  end
  
  def prevent_destroy
    errors.add(:base, "Transactions are append-only and cannot be deleted")
    throw :abort
  end
end