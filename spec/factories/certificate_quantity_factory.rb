FactoryBot.define do
  factory :certificate_quantity do
    quantity { 50 }
    certificate { create(:certificate) }
    account { certificate.generator.organization.default_account }
    status { 'active' }
  end
end
