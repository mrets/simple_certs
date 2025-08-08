class Certificate < ApplicationRecord
  belongs_to :generator
  belongs_to :generation
  has_many :certificate_quantities

  before_save :assign_vintage_date
  before_save :assign_serial_number
  after_create :create_certificate_quantity_with_logging

  def assign_vintage_date
    self.vintage_date = generation.end_date.beginning_of_month
  end

  def assign_serial_number
    self.sn_base = "#{vintage_date.strftime('%Y-%m')}-#{SecureRandom.hex[0..7]}"
  end

  def create_certificate_quantity_with_logging
    ActiveRecord::Base.transaction do
      # Create the certificate quantity
      certificate_quantity = self.certificate_quantities.create!(
        quantity: quantity,
        account: generator.organization.default_account,
        status: "active"
      )
      
      # Log the certificate issuance
      logger = TransactionLogger.new(
        organization: generator.organization
      )
      logger.log_certificate_issuance(self, certificate_quantity)
    end
  rescue => e
    # Log the error if creation fails
    logger = TransactionLogger.new(
      organization: generator.organization
    )
    logger.log_error(Transaction::EVENT_TYPES[:certificate_issued], e,
                    certificate: self,
                    metadata: { 
                      generator_id: generator_id,
                      generation_id: generation_id 
                    })
    raise
  end
  
  private
  
  # Maintain backward compatibility
  alias_method :create_certificate_quantity, :create_certificate_quantity_with_logging
end