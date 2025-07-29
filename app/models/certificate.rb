class Certificate < ApplicationRecord
  belongs_to :generator
  belongs_to :generation
  has_many :certificate_quantities
end