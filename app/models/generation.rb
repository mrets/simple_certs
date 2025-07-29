class Generation < ApplicationRecord
  belongs_to :generator

  scope :for_organization, ->(org) { joins(:generator).where(generators: { organization_id: org.id }) }
end