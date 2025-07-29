class CertificateQuantity < ApplicationRecord
  belongs_to :certificate
  belongs_to :account
end 