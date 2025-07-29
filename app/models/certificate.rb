class Certificate < ApplicationRecord
  belongs_to :generator
  has_many :certificate_quantities
end