class CertificateQuantity < ApplicationRecord
  belongs_to :certificate
  belongs_to :account
  belongs_to :to_organization, class_name: "Organization", foreign_key: "to_organization_id", optional: true

  enum :status, %w[active intransit retired].index_by(&:itself)
  after_update :set_status_changed_at, if: -> { saved_change_to_status? }

  scope :stale_transfers, -> { intransit.where(status_changed_at: ..24.hours.ago) }

  def split(quantity)
    self.class.create(certificate: certificate, account: account, quantity: self.quantity - quantity, status: "active")
    update(quantity: quantity)
  end

  private

  def set_status_changed_at
    update_column(:status_changed_at, Time.zone.now)
  end
end
