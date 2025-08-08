class Generation < ApplicationRecord
  belongs_to :generator
  has_one :certificate

  scope :for_organization, ->(org) { joins(:generator).where(generators: { organization_id: org.id }) }

  after_commit :issue_certificate_with_logging, on: :create

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :quantity, presence: true

  validate :start_date_is_less_than_end_date
  validate :start_date_is_not_in_the_future
  validate :end_date_is_not_in_the_future

  def issue_certificate_with_logging
    # Log generation creation first (outside any transaction)
    logger = TransactionLogger.new(
      organization: generator.organization
    )
    logger.log_generation_created(self)
    
    # Create the certificate (which will trigger its own logging)
    self.certificate = Certificate.create!(
      quantity: self.quantity,
      generator: self.generator,
      generation: self
    )
  rescue => e
    # Log the error if certificate creation fails
    logger ||= TransactionLogger.new(
      organization: generator.organization
    )
    logger.log_error(Transaction::EVENT_TYPES[:certificate_issued], e,
                    generation: self,
                    metadata: { 
                      generator_id: generator_id,
                      quantity: quantity 
                    })
    raise
  end

  def start_date_is_less_than_end_date
    if start_date > end_date
      errors.add(:base, "start date #{start_date} is not less the than end date #{end_date}")
    end
  end

  def start_date_is_not_in_the_future
    if start_date > Date.today
      errors.add(:base, "start date #{start_date} is in the future")
    end
  end

  def end_date_is_not_in_the_future
    if end_date > Date.today
      errors.add(:base, "end date #{end_date} is in the future")
    end
  end
  
  private
  
  # Maintain backward compatibility
  alias_method :issue_certificate, :issue_certificate_with_logging
end