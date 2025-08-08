class Certificate < ApplicationRecord
  include Loggable

  belongs_to :generator
  belongs_to :generation
  has_many :certificate_quantities

  before_save :assign_vintage_date
  before_save :assign_serial_number
  after_create :create_certificate_quantity

  def assign_vintage_date
    self.vintage_date = generation.end_date.beginning_of_month
  end

  def assign_serial_number
    self.sn_base = "#{vintage_date.strftime('%Y-%m')}-#{SecureRandom.hex[0..7]}"
  end

  def create_certificate_quantity
    self.certificate_quantities << CertificateQuantity.new(
      quantity: quantity,
      account: generator.organization.default_account,
      status: "active"
    )
  end
end
