class Certificate < ApplicationRecord
  belongs_to :generator
  belongs_to :generation
  has_many :certificate_quantities

  after_create :create_certificate_quantity

  def create_certificate_quantity
    self.certificate_quantities << CertificateQuantity.new(
      quantity: quantity,
      account: generator.organization.default_account
    )
  end
end