class Generation < ApplicationRecord
  belongs_to :generator
  has_one :certificate

  scope :for_organization, ->(org) { joins(:generator).where(generators: { organization_id: org.id }) }

  after_create :issue_certificate

  def issue_certificate
    self.certificate = Certificate.new(
      quantity: self.quantity,
      generator: self.generator
    )
  end
end