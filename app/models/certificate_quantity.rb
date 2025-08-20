class CertificateQuantity < ApplicationRecord
  belongs_to :certificate
  belongs_to :account
  belongs_to :to_organization, class_name: "Organization", foreign_key: "to_organization_id", optional: true

  enum :status, %w[active intransit retired].index_by(&:itself)

  def split(quantity)
    self.class.create(certificate: certificate, account: account, quantity: self.quantity - quantity, status: "active")
    update(quantity: quantity)
  end
end
